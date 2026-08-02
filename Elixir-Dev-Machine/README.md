# Elixir Dev Machine
## for editing and developing Elixir (Phoenix Framework) projects.

Uses Docker Compose

To create a container with a git repo:
```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
docker compose build --build-arg REPO=git@github.com:username/repo.git 

```

Or to create a container without a preset repo:
```
docker compose build --build-arg REPO=git 
```

