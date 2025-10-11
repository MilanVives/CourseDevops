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

**Les 5 – Infrastructure as Code (IAC)**

- Van handmatige naar geautomatiseerde infrastructuur
- **Ansible**: Configuration Management
  - Playbooks, inventory, modules en roles
  - Ad-hoc commands en automation workflows
  - Best practices en Vault voor secrets
- **Terraform/OpenTofu**: Infrastructure Provisioning
  - Declaratieve vs imperatieve benaderingen
  - HCL syntax en resource management
  - State management en lifecycle workflows
  - Resource cleanup en destroy best practices
- Tool integratie: Terraform + Ansible workflows
- Praktische cloud deployment (GCP/AWS/Azure)
- Cost management en automated cleanup

**Les 6 – Kubernetes Fundamentals**

- Container orchestratie op enterprise schaal
- Kubernetes architectuur: control plane, nodes, pods
- Core concepts: Pods, Services, Deployments
- Kubernetes manifests en YAML configuratie
- Service discovery en load balancing
- ConfigMaps en Secrets management

**Les 7 – Kubernetes Cloud Deployment**

- Managed Kubernetes services (GKE, EKS, AKS)
- Cloud-native deployment strategieën
- Ingress controllers en external access
- Persistent volumes in de cloud
- Auto-scaling en resource management

**Les 8 – Kubernetes Local Development**

- Minikube en lokale development clusters
- Kind (Kubernetes in Docker)
- Development workflows met Kubernetes
- Debugging en troubleshooting
- Praktische hands-on labs

**Les 9 – CI/CD Pipelines**

- Continuous Integration en Deployment
- GitOps workflows en automation
- Container-based CI/CD pipelines
- Infrastructure as Code in CI/CD
- Testing strategieën en deployment patterns

**Les 10 – Helm Package Management**

- Kubernetes applicatie packaging
- Helm charts en templating
- Package management en versioning
- Custom charts en repository management
- Deployment automation met Helm

**Les 11 – Ingress & Reverse Proxies**

- Traefik als modern reverse proxy
- Ingress controllers en routing
- Load balancing strategieën
- SSL/TLS certificate management
- Service mesh introductie

**Les 12 – Monitoring & Observability**

- Observability: metrics, logs, tracing
- Prometheus voor metrics collection
- Grafana voor visualization
- Logging strategieën en log aggregation
- Application performance monitoring

**Les 13 – Advanced Cloud Native Topics**

- CDN integratie (Cloudflare)
- Security best practices en compliance
- Performance optimization strategieën
- Disaster recovery en backup strategieën
- Future trends: serverless, edge computing

---

# Introductie

Deze cursus **DevOps & Cloud Native** biedt een praktijkgerichte inleiding in de moderne manier van software ontwikkelen, uitrollen en beheren.  

We starten met **Docker** als basis van containerisatie, gevolgd door **Dockerfile** en **Docker Compose** voor multi-container applicaties. Vervolgens leren we **Docker Networking** voor complexe communicatie patronen.

Een belangrijke stap is **Infrastructure as Code (IAC)** met **Ansible** en **Terraform**, waarmee we complete infrastructuur automatiseren. Daarna bouwen we verder naar **Kubernetes** voor enterprise orchestratie, **CI/CD** pipelines, en cloud-native tools zoals **Helm, Traefik en monitoring oplossingen**.

### Doelstellingen

- Begrijpen waarom containerisatie en orkestratie essentieel zijn voor moderne software development.
- Leren werken met Docker ecosysteem voor development, testing en productie.
- Infrastructure as Code beheersen voor geautomatiseerd infrastructuur beheer.
- Inzicht krijgen in Kubernetes als standaard voor cloud deployment en orchestratie.
- Kennismaken met CI/CD pipelines, monitoring en enterprise-ready infrastructuurtools.
- Praktische ervaring opbouwen met industry-standard DevOps workflows.

### Voor wie?

- Studenten en professionals die inzicht willen krijgen in **DevOps** en **Cloud Native development**.
- Basiskennis Linux en command line is een pluspunt.
- Interesse in automatisering, cloud platforms en moderne development practices.
- Voorbereiding op DevOps Engineer, Site Reliability Engineer of Cloud Infrastructure rollen.

---
