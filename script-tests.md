```sh

scalp@Host-002 okdp-live % curl -s -o /dev/null -w 'API through the ingress → %{http_code}\n' https://okdp-ui.okdp.sandbox/api/projects
API through the ingress → 200
scalp@Host-002 okdp-live % curl -s https://okdp-ui.okdp.sandbox/api/projects | jq
[
  {
    "name": "jp",
    "description": ""
  },
  {
    "name": "uitest",
    "description": "Project created through the console to test PR 90"
  }
]
scalp@Host-002 okdp-live % curl -s -X POST https://okdp-ui.okdp.sandbox/api/projects -H 'Content-Type: application/json' -d '{"name":"authdemo","description":"created with no credentials"}' | jq; echo "--- did a real namespace appear? ---"; kubectl get ns authdemo
{
  "name": "authdemo",
  "description": "created with no credentials"
}
--- did a real namespace appear? ---
NAME       STATUS   AGE
authdemo   Active   0s
scalp@Host-002 okdp-live % curl -s -o /dev/null -w 'DELETE → %{http_code}\n' -X DELETE https://okdp-ui.okdp.sandbox/api/projects/authdemo; kubectl get ns authdemo
DELETE → 204
NAME       STATUS        AGE
authdemo   Terminating   84s
scalp@Host-002 okdp-live % curl -s https://okdp-ui.okdp.sandbox/api/projects | jq
[
  {
    "name": "jp",
    "description": ""
  },
  {
    "name": "uitest",
    "description": "Project created through the console to test PR 90"
  }
]
scalp@Host-002 okdp-live % curl -s -X POST https://okdp-ui.okdp.sandbox/api/projects -H 'Content-Type: application/json' -d '{"name":"authdemo","description":"created with no credentials"}' | jq; echo "--- did a real namespace appear? ---"; kubectl get ns authdemo
{
  "name": "authdemo",
  "description": "created with no credentials"
}
--- did a real namespace appear? ---
NAME       STATUS   AGE
authdemo   Active   0s
scalp@Host-002 okdp-live % curl -s https://okdp-ui.okdp.sandbox/api/projects | jq
[
  {
    "name": "authdemo",
    "description": "created with no credentials"
  },
  {
    "name": "jp",
    "description": ""
  },
  {
    "name": "uitest",
    "description": "Project created through the console to test PR 90"
  }
]
scalp@Host-002 okdp-live % curl -s -o /dev/null -w 'DELETE → %{http_code}\n' -X DELETE https://okdp-ui.okdp.sandbox/api/projects/authdemo; kubectl get ns authdemo
DELETE → 204
NAME       STATUS        AGE
authdemo   Terminating   7s
scalp@Host-002 okdp-live % curl -s https://okdp-ui.okdp.sandbox/api/projects | jq                                                                                 
[
  {
    "name": "authdemo",
    "description": "created with no credentials"
  },
  {
    "name": "jp",
    "description": ""
  },
  {
    "name": "uitest",
    "description": "Project created through the console to test PR 90"
  }
]
scalp@Host-002 okdp-live % curl -s https://okdp-ui.okdp.sandbox/api/projects | jq
[
  {
    "name": "authdemo",
    "description": "created with no credentials"
  },
  {
    "name": "jp",
    "description": ""
  },
  {
    "name": "uitest",
    "description": "Project created through the console to test PR 90"
  }
]
scalp@Host-002 okdp-live % curl -s -o /dev/null -w 'DELETE → %{http_code}\n' -X DELETE https://okdp-ui.okdp.sandbox/api/projects/authdemo; kubectl get ns authdemo
DELETE → 404
Error from server (NotFound): namespaces "authdemo" not found
scalp@Host-002 okdp-live % curl -s https://okdp-ui.okdp.sandbox/api/projects | jq                                                                                 
[
  {
    "name": "jp",
    "description": ""
  },
  {
    "name": "uitest",
    "description": "Project created through the console to test PR 90"
  }
]
scalp@Host-002 okdp-live % curl -s https://okdp-ui.okdp.sandbox/api/projects
[{"name":"jp","description":""},{"name":"uitest","description":"Project created through the console to test PR 90"}]%            
```
