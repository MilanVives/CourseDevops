# 🌩 Permanente Evaluatieopdracht 3 — Minikube 2/20ptn

## 🎯 Doel van de opdracht

In deze opdracht toon je aan dat je in staat bent om een eenvoudige cloud-ready applicatie te ontwerpen, op te bouwen en te deployen met **Minikube**. Je leert hoe je meerdere services combineert in één samenwerkend geheel met behulp van **Kubernetes manifests** en hoe je gebruik maakt van **ConfigMaps** en **Secrets** voor configuratiebeheer.

---

## 🧩 Opdrachtomschrijving

Je deployt dezelfde **drieservicetoepassing** uit PE2 bestaande uit:

1. **Frontend** – Je **React Native**-applicatie uit de les Cross Platform.
2. **Backend** – Je **Java Springboot** API uit de les Java Backend.
3. **Database** – bijvoorbeeld **Postgres DB**.

De drie onderdelen moeten samenwerken binnen een **Minikube** cluster. Je gebruikt de Docker images die je hebt gemaakt in PE2 en deployt deze naar Kubernetes met behulp van manifests.

---

## 🧱 Vereisten

### 1. Structuur

- Elk van de drie services moet gedefinieerd worden in aparte Kubernetes manifest bestanden.
  ```
  /k8s-manifests
    /frontend
      deployment.yaml
      service.yaml
    /backend
      deployment.yaml
      service.yaml
    /database
      deployment.yaml
      service.yaml
      configmap.yaml
      secret.yaml
  minikube_deployment.md
  ```
- De applicatie moet **functioneel samen werken** binnen het Kubernetes cluster.

---

### 2. Kubernetes Manifests

- Maak **Deployment** manifests voor alle drie de services (frontend, backend, database).
- Maak **Service** manifests om communicatie tussen de services mogelijk te maken.
- Gebruik je **Docker Hub images** uit PE2 voor frontend en backend.
- De **database** gebruikt een officiële Docker Hub image (bv. `postgres:latest`).

---

### 3. ConfigMaps en Secrets

- Maak een **ConfigMap** voor de database URL (DB_URL) en andere niet-gevoelige configuratie.
- Maak een **Secret** voor database credentials (gebruikersnaam, wachtwoord).
- De backend deployment moet deze ConfigMap en Secret gebruiken via environment variables.

---

### 4. Minikube Deployment

- Deploy alle manifests naar je **Minikube** cluster.
- Zorg dat de frontend service toegankelijk is vanaf de host machine (gebruik `minikube service` of NodePort).
- Test de volledige applicatie workflow binnen het cluster.

---

### 5. Documentatie – minikube_deployment.md

Maak een Markdown-bestand (`minikube_deployment.md`) met volgende inhoud:

#### 📘 Inhoud:

1. **Korte beschrijving van je drie services**
   - Wat doet elke service in de Kubernetes context?
2. **Minikube setup instructies**
   - Commando's om Minikube te starten en je applicatie te deployen.
3. **Uitleg over je Kubernetes manifests**
   - Welke resources heb je gedefinieerd?
   - Hoe communiceren de services binnen het cluster?
   - Welke ConfigMaps en Secrets heb je gebruikt?
4. **Toegang tot de frontend**
   - Instructies om de frontend service te benaderen vanaf de host machine.
5. **Screenshots:**
   - Terminal-output van `kubectl get all` na succesvolle deployment
   - Browserweergave van de werkende applicatie via Minikube
   - Output van `kubectl describe` voor één van je deployments
6. **Conclusie of reflectie**
   - Verschillen tussen Docker Compose en Kubernetes deployment
   - Wat heb je geleerd of wat waren de uitdagingen?

---

### 6. Versiebeheer (GitHub Classroom)

- Push **alle Kubernetes manifests** en **minikube_deployment.md** naar je **officiële GitHub Classroom repository**.
- Organiseer de bestanden in een duidelijke mappenstructuur.
- Zorg dat alle manifests succesvol kunnen worden toegepast op een vers Minikube cluster.

---

## ✅ Beoordelingscriteria

| Onderdeel | Punten | Criteria |
|-----------|---------|----------|
| Kubernetes manifests (Deployments & Services) | 0.6 | Correcte YAML syntax, alle services deployen succesvol |
| ConfigMaps & Secrets implementatie | 0.4 | Juist gebruik van ConfigMaps voor DB_URL en Secrets voor credentials |
| Werkende applicatie in Minikube | 0.5 | Alle services communiceren correct binnen het cluster |
| Frontend toegankelijkheid | 0.2 | Frontend is bereikbaar vanaf host machine |
| Documentatie (minikube_deployment.md) | 0.2 | Volledig, duidelijk, met screenshots en instructies |
| GitHub repository | 0.1 | Correcte structuur en duidelijke organisatie |

**Totaal: 2 punten**

---

## ⚙️ Praktische tips

- Start Minikube met voldoende resources: `minikube start --memory=4096 --cpus=2`.
- Test je manifests eerst individueel met `kubectl apply -f` voordat je alles deployt.
- Gebruik `kubectl logs` om problemen te debuggen.
- Controleer of je Docker Hub images publiek beschikbaar zijn.
- Gebruik `kubectl port-forward` als alternatief voor service toegang tijdens development.
- Test de volledige workflow: `kubectl delete -f .` gevolgd door `kubectl apply -f .`.

---

## 📅 Deadline

> **donderdag 4 december 2025 om 13:59**.
