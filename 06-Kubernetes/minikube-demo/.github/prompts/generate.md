Create a extremely simpliefied 3 basic tier app in the MERN stack. 

The app is a simple Pet shelter app and returns all pets aor you can add one. 

The Node API contains only the those two endpoints and not protected. 

The goal is to first use this app to create Docker images, then run it with docker compose and then later on with kubernetes. 

For Kubernetes we will push the images to dockerhub, my username is dimilan.

Add a .ignore for all node_modules and all .DS_Store files

We will use minikube as a kubernetes cluster, create no ingress. 

With kubernetes we will use secrets and configmap for the mongo url and user and password. 

Also create the Readme.md file with explainations about the project

Keep all functionality, files and kubernetes yaml files exteremly simple, the bare minimum for them to work. 

We well publish the service with minikube service [service name]