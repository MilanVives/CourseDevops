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

## [Les 1 – Docker Basics](1-Docker/)

- [Docker Fundamentals](1-Docker/docker.md) - Introductie & Motivatie, Wat is Docker?, Containers vs VMs
- [Praktische Oefeningen](1-Docker/oefeningen.md) - Hands-on labs en experimenteren
- **Onderwerpen:**
  - Belangrijkste Docker commando's (`docker run`, `docker ps`, `docker stop`, `docker rm`)
  - Opties: `--rm`, `--name`, `-d`, `-p`, `-v`
  - `docker inspect`
  - Data & Volumes: ephemeral, named, bind mounts, `--volumes-from`
  - Networking: bridge, poortmapping, container-naar-container communicatie
  - Eigen images maken met `docker commit`
  - Publiceren naar Docker Hub

## [Les 2 – Dockerfile](2-Dockerfile/)

- [Dockerfile Tutorial](2-Dockerfile/Dockerfile-Intro.md) - Van Docker run naar distribueerbare images
- **Onderwerpen:**
  - Images bouwen met Dockerfile
  - Docker layer systeem en caching
  - Dockerfile keywords en best practices
  - Multi-stage builds en optimization
  - Van handmatige containers naar scripted builds

## [Les 3 – Docker Compose](3-Compose/)

- [Van Docker run naar Compose](3-Compose/compose.md) - Multi-container orchestratie
- [Compose bestanden](3-Compose/compose-files/) - Praktische voorbeelden
- **Onderwerpen:**
  - Multi-container applicaties
  - YAML configuratie en service definitie
  - Container communicatie via service names
  - Volumes en networking in Compose
  - Van handmatige linking naar geautomatiseerde orchestratie

## [Les 4 – Docker Networking](4-Docker-networking/)

- [Docker Networking Tutorial](4-Docker-networking/docker-networking.md) - Complete netwerkgids
- **Onderwerpen:**
  - Netwerkmodi: bridge, host, overlay, none
  - Container-naar-container communicatie
  - Custom networks aanmaken en beheren
  - Network drivers en gebruik cases
  - Externe toegang en poort forwarding
  - Praktische voorbeelden met netcat

## [Les 5 – Infrastructure as Code (IaC)](5-IaC/)

- [IaC Tutorial](5-IaC/iac.md) - Ansible en Terraform mastery
- [IaC bestanden](5-IaC/iac-files/) - Praktische voorbeelden en templates
- **Onderwerpen:**
  - Van handmatige naar geautomatiseerde infrastructuur
  - **Ansible**: Configuration Management, Playbooks, inventory, modules en roles
  - **Terraform/OpenTofu**: Infrastructure Provisioning, declaratieve vs imperatieve benaderingen
  - State management en lifecycle workflows
  - Resource cleanup en destroy best practices
  - Tool integratie: Terraform + Ansible workflows
  - Praktische cloud deployment (GCP/AWS/Azure)

## [Les 6 – Kubernetes](6-Kubernetes/)

### [Les 6a – Kubernetes Cloud Deployment (Easy Start)](6-Kubernetes/kubernetes-cloud-start.md)
- Waarom Kubernetes? Container orchestratie uitdagingen
- Managed Kubernetes: Linode Kubernetes Engine (LKE) quick start
- Cloud deployment: van Docker Compose naar Kubernetes
- Basic deployment op managed cluster
- LoadBalancer services en external access

### [Les 6b – Kubernetes Fundamentals & Local Development](6-Kubernetes/kubernetes-fundamentals.md)
- **Kubernetes Architectuur**: control plane, nodes, pods  
- **Core Concepts Deep Dive**: Pods, Services, Deployments
- **Kubernetes Manifests**: YAML configuratie en best practices
- **Service Discovery**: load balancing mechanismen
- **ConfigMaps en Secrets**: configuration management
- **Namespaces**: resource isolation en multi-tenancy
- **Labels & Selectors**: resource organization en targeting
- **Three-tier Application**: frontend, backend, database deployment
- **Local Development**: Minikube en Kind (Kubernetes in Docker)
- **Development Workflows**: hot reloading en debugging
- **Troubleshooting**: praktische debugging technieken

## [Les 7 – Helm Package Management](7-Helm/)

- [Helm Tutorial](7-Helm/helm.md) - Kubernetes package management
- **Onderwerpen:**
  - Kubernetes applicatie packaging en templating
  - Helm charts en custom chart development
  - Package management en versioning strategieën
  - Helm repositories en chart distribution
  - Complex deployments met Helm dependency management

## [Les 8 – Ingress & Reverse Proxies](8-Ingress-and-Reverse-Proxies/)

- [Ingress en Traefik](8-Ingress-and-Reverse-Proxies/ingress.md) - Modern reverse proxy
- **Onderwerpen:**
  - Traefik als modern reverse proxy
  - Ingress controllers en routing
  - Load balancing strategieën
  - SSL/TLS certificate management met cert-manager
  - External DNS en domain management

## [Les 9 – CI/CD](9-CI-CD/)

- **Onderwerpen:**
  - GitOps principes en workflow patterns
  - ArgoCD voor declaratieve deployments
  - Flux voor continuous delivery
  - Infrastructure as Code in CI/CD pipelines
  - Multi-environment deployment strategieën
  - Canary deployments en blue-green patterns

## [Les 10 – Service Mesh & Microservices](10-Service-Mesh-and-Microservices/)

- [Service Mesh Tutorial](10-Service-Mesh-and-Microservices/service-mesh.md) - Advanced microservices communication
- **Onderwerpen:**
  - Service mesh architectuur en use cases
  - Istio: traffic management, security, observability
  - Linkerd als lightweight alternatief  
  - Service-to-service communication patronen
  - Circuit breakers en resilience patterns
  - Microservices observability en debugging

## [Les 11 – Security & DevSecOps](11-Security-and-Devops/)

- **Onderwerpen:**
  - Container security best practices
  - Image vulnerability scanning (Trivy, Snyk)
  - Kubernetes security: RBAC, PodSecurityPolicies
  - Policy as Code met Open Policy Agent (OPA)
  - Secrets management en encryption
  - Security monitoring en compliance automation

## [Les 12 – Advanced Monitoring & Observability](12-Monitoring/)

- **Onderwerpen:**
  - Observability: metrics, logs, distributed tracing
  - Prometheus voor metrics collection en alerting
  - Grafana voor visualization en dashboards
  - Jaeger voor distributed tracing
  - Application Performance Monitoring (APM)
  - SLA/SLO/SLI definitie en monitoring

## [Les 13 – Performance & Scalability](13-Scalability/)

- **Onderwerpen:**
  - Kubernetes auto-scaling: HPA, VPA, Cluster Autoscaler
  - Load testing strategieën (K6, Artillery)
  - Performance optimization technieken
  - Resource management en capacity planning
  - Multi-cloud en hybrid cloud strategieën
  - Disaster recovery en business continuity planning

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