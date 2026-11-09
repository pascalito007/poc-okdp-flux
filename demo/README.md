# Démo OKDP : de la description d'une plateforme à son déploiement

Ce dossier montre, sur deux exemples, comment OKDP passe d'une **description courte** de ce qu'on veut
(« un JupyterHub qui a sa base dans le PostgreSQL de la plateforme ») à un **déploiement réel** dans
Kubernetes, sans que personne n'écrive d'adresse, de mot de passe ni d'ordre d'installation.

Le moteur est écrit en [Pkl](https://pkl-lang.org) (langage de configuration d'Apple). Il est le résultat
d'une comparaison de sept outils (voir « Pour aller plus loin »).

---

## 1. Les deux parcours d'intégration

Chaque parcours est un fichier de plateforme, commenté avec son histoire.

**JupyterHub** ([platforms/jupyterhub-tenant.yaml](platforms/jupyterhub-tenant.yaml))
> Dans mon environnement okdp-demo, je veux un JupyterHub. JupyterHub a besoin d'une base de données pour
> ses données internes (utilisateurs, sessions). Je ne veux pas lui dédier un serveur : je veux qu'il ait
> sa base et son compte dans un PostgreSQL partagé de la plateforme.

Résultat : 5 unités à installer, 1 raccordement (`hub.hubDb`).

**Trino** ([platforms/trino-tenant.yaml](platforms/trino-tenant.yaml))
> Dans mon environnement okdp-demo, je veux un Trino pour interroger en SQL des tables Hive. Trino a besoin
> d'un catalogue de tables (Hive Metastore) et d'un accès au stockage objet (S3) où les fichiers sont
> rangés. Je veux que Trino utilise le Hive Metastore de la plateforme, et qu'il reçoive son propre accès
> au bucket « hive » du stockage S3 de la plateforme.

Résultat : 10 unités, 4 raccordements (la base et le bucket du Metastore, le catalogue et le bucket de Trino).

Les deux parcours ont été déployés en vrai avec Argo CD : JupyterHub crée ses tables dans sa base, Trino
crée, remplit (`INSERT`) et relit une table Hive sur S3.

---

## 2. Les notions, en une ligne chacune

| Notion | Où | Ce que c'est |
|---|---|---|
| **Catalogue** | `catalog/` | le « menu » maintenu par OKDP : services, contrats, provisioners, charts |
| **Plateforme** | `platforms/*.yaml` | la « commande » du gestionnaire : quelles instances, raccordées à quoi |
| **Contrat** | `catalog/contracts/` | la forme d'un raccordement : ce qu'on peut demander (`claim`) et ce qu'on reçoit (`binding` + clés secrètes) |
| **Slot** | `connexions:` d'un service | un point de raccordement du service, avec les contrats qu'il **accepte** (`accepts`) |
| **`defaults`** d'un slot | dans le slot | valeurs que **ce service** fixe d'office (ex. l'adresse de retour OIDC de JupyterHub) ; elles remplacent les valeurs par défaut du contrat |
| **Connexion** | `connect:` d'une instance | le raccordement réel : à quel fournisseur, dans quel mode, avec quel `claim` |
| **Claim** | `claim:` d'une connexion | ce que ce déploiement demande (ex. `database: jupyterhub`) |
| **Mode** | `mode:` | `tenant` (une place dans un fournisseur partagé), `dedicated` (un fournisseur rien que pour soi), `existing` (quelque chose qui existe déjà), `bind` (juste une adresse) |
| **Provisioner** | `catalog/provisioners/` + chart | ce qui crée réellement la base, le compte, le bucket… au déploiement, et range les identifiants dans un Secret |
| **Binding** | dans le plan | les valeurs que le consommateur reçoit (adresse, port, URL…) et le nom du Secret de ses identifiants |
| **Mapping** | `engine-pkl/mappings/` | la traduction d'un binding vers les values du chart officiel d'un service |
| **Plan** | `out/<plateforme>/plan.json` | le résultat de compose : tout ce qu'il faut installer, dans quel ordre, avec quelles values |
| **Unité** | `units` du plan | une chose à installer (un chart), avec ses dépendances (`needs`) et sa vague (`wave`) |

La démo ne parle pas de « familles » : un slot liste directement les contrats qu'il accepte.

---

## 3. Ce qui se passe, étape par étape (parcours JupyterHub)

Les étapes 2 à 6 sont faites par **compose**, en une seule exécution. L'étape 7 est faite par **emit**,
l'étape 8 par l'outil de déploiement.

**1. Le gestionnaire écrit sa plateforme.** Une ligne suffit pour le raccordement :
```yaml
hubDb: { provider: pg, mode: tenant, claim: { database: jupyterhub } }
```
Il n'écrit ni adresse, ni mot de passe, ni ordre.

**2. Quel contrat ?** Le moteur garde ce que le fournisseur `pg` offre dans le mode `tenant`, et que le slot
`hubDb` accepte ; il doit en rester un seul : `postgresql-database`.
→ [compose.pkl:129-133](engine-pkl/engine/compose.pkl:129), [jupyterhub.yaml:10](catalog/services/jupyterhub.yaml:10), [postgresql-cnpg.yaml:8](catalog/services/postgresql-cnpg.yaml:8)

**3. Qui crée la base ?** Ni JupyterHub ni `pg`. Le moteur choisit un **provisioner** dans la liste du contrat,
selon la sorte du fournisseur (`service/postgresql-cnpg`) et le mode : `cnpg-tenant`, chart `okdp-pg-binding`.
Il devient une unité à installer, `bind-hub-hubdb`. Au déploiement, ce chart déclare à CNPG un `DatabaseRole`
(le compte) et une `Database`, génère le mot de passe et le range dans le Secret `okdp-bind-hub-hubdb`.
→ [compose.pkl:149-155](engine-pkl/engine/compose.pkl:149), [provisioners/postgresql-database.yaml:8-12](catalog/provisioners/postgresql-database.yaml:8), [cnpg-tenant.yaml:13](catalog/charts/okdp-pg-binding/templates/cnpg-tenant.yaml:13)

**4. Quelles valeurs JupyterHub recevra ?** Le moteur empile : les valeurs par défaut du contrat, puis ce que
le fournisseur annonce (sa fonction `offer` : adresse, port, nom de base pris dans le claim), puis la
technologie, puis les URL fabriquées à partir des modèles du contrat (`uri`, `jdbcUrl`, `sqlalchemyUrl`).
Le claim, lui, s'empile aussi : défauts du contrat, puis `defaults` du slot, puis claim de la connexion.
Le résultat est vérifié avec les schémas du contrat. **Aucun mot de passe dans le plan.**
→ [compose.pkl:195](engine-pkl/engine/compose.pkl:195) (claim), [235-241](engine-pkl/engine/compose.pkl:235) (valeurs), [postgresql-cnpg.pkl:17-23](engine-pkl/mappings/postgresql-cnpg.pkl:17), [contracts/postgresql-database.yaml:10-33](catalog/contracts/postgresql-database.yaml:10)

**5. Comment JupyterHub les reçoit ?** Son chart officiel n'est pas modifié. Le **mapping** traduit le binding
dans les values du chart : l'URL va dans `hub.db.url`, les identifiants sont **désignés** (variables
d'environnement lues dans le Secret), jamais copiés.
→ [jupyterhub.pkl:8](engine-pkl/mappings/jupyterhub.pkl:8), [24](engine-pkl/mappings/jupyterhub.pkl:24), [33](engine-pkl/mappings/jupyterhub.pkl:33)

**6. Dans quel ordre ?** Le moteur déduit qui attend qui (`needs`) : le consommateur attend son provisioner,
le provisioner attend son fournisseur, et une unité qui a besoin d'une capacité (`cnpg`, `eso`) attend
l'instance qui l'offre. Il en tire des vagues : opérateurs (0) → `pg` (1) → `bind-hub-hubdb` (2) → `hub` (3).
→ [compose.pkl:324-329](engine-pkl/engine/compose.pkl:324), [395](engine-pkl/engine/compose.pkl:395), [408](engine-pkl/engine/compose.pkl:408)

**7. Emit traduit le plan pour chaque outil.** Il ne lit que `units` du plan et écrit `argocd/`, `flux/`,
`helm/`, `helmfile/`, `umbrella/` et `INSTALL.md`. Pour Argo CD : une `Application` par unité, la vague
devient `sync-wave`, les values deviennent `valuesObject`.
→ [engine-pkl/emit/](engine-pkl/emit/) (un fichier par sortie)

**8. Argo CD déploie**, vague par vague. Une règle de santé (`argocd-cm-application-health.yaml`, générée)
garantit qu'une vague attend vraiment que la précédente soit prête.

**Particularité du parcours Trino.** Trino se raccorde au Hive Metastore en mode `bind` : le Metastore n'a pas
d'identifiants, Trino reçoit seulement son adresse (`thrift://hive…:9083`), sans provisioner. En revanche,
Trino reçoit son **propre** accès au bucket, distinct de celui du Metastore. La base du Metastore contient la
description des tables ; les fichiers sont dans le bucket.

---

## 4. Les fichiers

```
platforms/                  les deux parcours (la seule chose qu'écrit le gestionnaire)
catalog/
  contracts/                postgresql-database, s3-bucket, hive-metastore, trino
  services/                 cloudnative-pg, external-secrets, postgresql-cnpg, seaweedfs, hive-metastore, jupyterhub, trino
  provisioners/             quel chart crée quoi, par contrat, sorte de fournisseur et mode
  charts/                   les charts OKDP : okdp-pg-binding, okdp-s3-binding, okdp-secrets
engine-pkl/
  compose.sh, emit.sh       les deux commandes
  engine/                   le moteur (voir ci-dessous)
  mappings/                 un fichier par service : values du chart et offres du fournisseur
  emit/                     une sortie par fichier : helm, helmfile, argocd, flux, umbrella, install
demo/                       scripts du déploiement Argo CD de démonstration
live/                       configuration du cluster kind et publication des charts
ENGINE-SPEC.md              les règles exactes du moteur (pour qui veut le modifier)
```

**Le moteur, fichier par fichier** (`engine-pkl/engine/`) :

| Fichier | Rôle |
|---|---|
| `model.pkl` | la forme de chaque objet (contrat, slot, service, connexion, binding, unité, plan) |
| `load.pkl` | lit les YAML, refuse les clés inconnues, remplit le modèle |
| `util.pkl` | les règles de nommage (`hub.hubDb` → `hub-hubdb`) et la fusion de values |
| `jsonschema.pkl` | vérifie claim et binding avec les schémas des contrats |
| `compose.pkl` | le chef d'orchestre : étapes 2 à 6, et toutes les erreurs (`ERROR: …`) |
| `ServiceMapping.pkl` | ce que chaque mapping doit fournir : `values(m)` et `offer(contrat, o)` |
| `okdp.pkl` | la boîte à outils des mappings (`one`, `bindingEnvMap`, `fromSecret`…) |

---

## 5. Lancer la démo

Toutes les commandes se lancent depuis ce dossier. Remplacez `kind-okdp-full` par votre contexte kubectl.

**Prérequis** : `pkl`, `kubectl`, `helm`, `jq`, `kind`, Docker ; un cluster kind (voir
[live/kind-okdp-full.yaml](live/kind-okdp-full.yaml)) et un registre local `kind-registry` (port 5001)
branché sur le réseau `kind`.

**Une fois, avant de présenter**

```bash
live/push-charts.sh oci://localhost:5001/okdp      # publie les charts OKDP dans le registre local
demo/argocd-install.sh kind-okdp-full               # Argo CD + serveur git interne, sans aucune application
```

Faites aussi **un passage complet de chaque parcours** (publish puis cleanup) : les images et les charts
seront en cache le jour J.

**Pendant la démo**

```bash
engine-pkl/compose.sh platforms/jupyterhub-tenant.yaml out/jupyterhub-tenant   # le plan
engine-pkl/emit.sh out/jupyterhub-tenant argocd                                 # les fichiers Argo CD
demo/argocd-publish.sh kind-okdp-full jupyterhub-tenant                         # publication : les applications apparaissent
kubectl --context kind-okdp-full -n argocd get applications -w                  # suivre les vagues
```

**Passer à l'autre parcours.** Les deux parcours déclarent les mêmes instances (opérateur CNPG, External
Secrets, `pg`) : ils ne peuvent pas tourner ensemble, et `argocd-publish.sh` le refuse en nommant la
plateforme à retirer.

```bash
demo/cleanup-argocd.sh kind-okdp-full jupyterhub-tenant
```

**Voir Argo CD dans le navigateur** : ouvrir un tunnel, puis `https://localhost:9443` (utilisateur `admin`).

```bash
kubectl --context kind-okdp-full -n argocd port-forward svc/argocd-server 9443:443
kubectl --context kind-okdp-full -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

**Les scripts de `demo/`**

| Script | Rôle |
|---|---|
| `argocd-install.sh <ctx>` | installe Argo CD, le serveur git interne et la déclaration des dépôts ; ce qui est déjà publié est conservé |
| `argocd-publish.sh <ctx> <plateforme>` | publie `out/<plateforme>/argocd` dans son propre dossier du dépôt git, applique la racine ; refuse si une autre plateforme installe déjà les mêmes objets ; relancer après un nouvel emit pour resynchroniser |
| `cleanup-argocd.sh <ctx> <plateforme>` | retire la racine, puis les applications de la dernière vague à la première, puis les namespaces (sauf ceux d'une autre plateforme), puis le dossier git |
| `full-argocd.sh <ctx> <plateforme>` | install puis publish d'un coup (à éviter pendant la démo : il réapplique l'installation d'Argo CD) |
| `git-server.sh`, `proxy.sh` | utilisés par les scripts ci-dessus |

**Pourquoi un serveur git dans le cluster ?** Argo CD ne lit que des dépôts git. En vrai, on pousserait le
dossier `argocd/` dans GitLab (un dossier par plateforme) ; ici, `git-server.sh` joue ce rôle. Argo CD ne lit
donc jamais votre disque : après un nouvel emit, il faut republier.

---

## 6. Sur le poste DGFiP

- **Proxy** : rien à faire. Les scripts lisent `HTTP_PROXY`, remplacent le nom du proxy par son adresse IP
  (les pods ne savent pas résoudre le nom) et montent le CA du poste dans Argo CD. Pour forcer une valeur :
  `OKDP_PROXY=http://<ip>:<port>`, ou `OKDP_PROXY=none`.
- **Après un redémarrage du poste**, si des pods système de kind plantent (`too many open files`) :
  ```bash
  sudo sysctl fs.inotify.max_user_watches=524288 fs.inotify.max_user_instances=512
  ```
  Pour que ce réglage tienne : `/etc/sysctl.d/99-kind.conf`.
- **`504 Gateway Timeout`** en téléchargeant un chart : le proxy a mis trop de temps. Relancer :
  `kubectl -n argocd annotate application <application> argocd.argoproj.io/refresh=hard --overwrite`.
- **Une application reste en `Sync Unknown`** : le message exact s'obtient avec
  `kubectl -n argocd get application <application> -o jsonpath='{.status.conditions[*].message}'`.

---

## 7. Ce que la démo ne montre pas (encore)

- **Deux parcours en même temps.** Ils partagent l'opérateur CNPG, External Secrets et le PostgreSQL. En vrai,
  une plateforme décrit tout un environnement : JupyterHub et Trino seraient dans la **même** plateforme, avec
  un seul PostgreSQL. Faire référence à une instance d'une autre plateforme n'existe pas encore.
- **Le catalogue n'est pas complet** : seuls les services, contrats et charts de ces deux parcours sont ici. Le
  catalogue complet (Iceberg/Polaris, Keycloak, Superset, Airflow, Spark…) est dans `../poc/catalog/`.
- **Écarts avec le POC** : la démo n'a pas de familles (`accepts` à la place) et autorise Trino à écrire dans
  les tables Hive existantes (`hive.non-managed-table-writes-enabled`). Le moteur de la démo n'est donc plus
  une copie conforme de `../poc/engine-pkl`.
- **La découverte des clés** : le fichier de plateforme n'a pas encore de schéma (pas d'autocomplétion), et les
  `parameters` d'un service ne sont décrits qu'en texte libre et ne sont pas vérifiés.

---

## 8. Pour aller plus loin

| Document | Pour quoi |
|---|---|
| [ENGINE-SPEC.md](ENGINE-SPEC.md) | les règles exactes du moteur et la liste des erreurs |
| `../guide/okdp-walkthrough.html` | la même histoire, illustrée, version POC (en anglais ; parle encore de familles) |
| `../docs/04-contract-model.md` | le modèle des contrats et des modes |
| `../docs/12-comparison-and-recommendation.md` | la comparaison des outils et pourquoi Pkl |
| `../docs/00-start-here.md` | le guide de lecture de toute l'étude |
