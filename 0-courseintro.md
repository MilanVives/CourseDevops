# DevOps & Cloud Native – Cursusmateriaal

## Auteur

**Milan Dima**  
[milan.dima@vives.be](mailto:milan.dima@vives.be)

## Licentie

Deze cursus valt onder de **Creative Commons BY 4.0-licentie**.  
Iedereen mag dit materiaal **gratis gebruiken, delen en aanpassen**,  
mits correcte bronvermelding naar: _Milan Dima (milan.dima@vives.be)_.

Meer info: [https://creativecommons.org/licenses/by/4.0/](https://creativecommons.org/licenses/by/4.0/)

---

# Inhoudstafel

**Les 1 – Docker Basics**

- Introductie & Motivatie
- Wat is Docker?
- Containers vs Virtuele Machines
- Belangrijkste Docker commando’s (`docker run`, `docker ps`, `docker stop`, `docker rm`)
- Opties: `--rm`, `--name`, `-d`, `-p`, `-v`
- `docker inspect`
- Data & Volumes: ephemeral, named, bind mounts
- Networking: bridge, poortmapping, container-naar-container communicatie
- Eigen images maken met `docker commit`
- Publiceren naar Docker Hub
- Practica (Labs)

**Les 2 – Dockerfile**

- Images bouwen met Dockerfile
- Lagen, caching en best practices
- Voorbeelden (custom images)

**Les 3 – Docker Compose**

- Multi-container applicaties
- YAML configuratie
- Voorbeeld: Drupal + PostgreSQL

**Les 4 – Docker Networking**

- Netwerkmodi: bridge, host, overlay
- Container-naar-container communicatie
- Externe toegang en poort forwarding

**Les 5 – Kubernetes Cloud Deployment**

- Introductie Kubernetes
- Pods, Services, Deployments
- Kubernetes in de cloud

**Les 6 – Kubernetes Minikube**

- Lokale Kubernetes cluster
- Praktische oefeningen

**Les 7 – CI/CD**

- Continuous Integration en Deployment
- Pipelines met containers

**Les 8 – Helm**

- Helm charts
- Deployment vereenvoudigen

**Les 9 – Reverse Proxies (Traefik)**

- Ingress controllers
- Load balancing en routing

**Les 10 – CDN (Cloudflare)**

- Content Delivery Networks
- DNS en caching

**Les 11 – Monitoring**

- Observability: metrics, logs, tracing
- Tools: Prometheus, Grafana

---

# Introductie

Deze cursus **DevOps & Cloud Native** biedt een praktijkgerichte inleiding in de moderne manier van software ontwikkelen, uitrollen en beheren.  
We starten met **Docker**, de basis van containerisatie, en bouwen verder op naar **Kubernetes**, **CI/CD** en cloud-native tools zoals **Helm, Traefik en Cloudflare**.

### Doelstellingen

- Begrijpen waarom containerisatie en orkestratie belangrijk zijn.
- Leren werken met Docker voor development, testing en productie.
- Inzicht krijgen in Kubernetes als standaard voor cloud deployment.
- Kennismaken met CI/CD pipelines, monitoring en moderne infrastructuurtools.

### Voor wie?

- Studenten en professionals die inzicht willen krijgen in **DevOps** en **Cloud Native development**.
- Basiskennis Linux en command line is een pluspunt.

---
