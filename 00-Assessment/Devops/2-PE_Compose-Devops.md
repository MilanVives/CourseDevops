# 🌩 Permanente Evaluatieopdracht 2 — Devops 2/20ptn

## 🎯 Doel van de opdracht

In deze opdracht toon je aan dat je in staat bent om een eenvoudige cloud-ready applicatie te ontwerpen, op te bouwen en te containeriseren met Docker. Je leert hoe je meerdere services combineert in één samenwerkend geheel met behulp van **Docker Compose**.

---

## 🧩 Opdrachtomschrijving

Je zoekt/ontwikkelt een originele **drieservicetoepassing** bestaande uit:

1. **Frontend** – Je **React Native**-applicatie uit de les Cross Platform.
2. **Backend** – Je **Java Springboot** API uit de les Java Backend.
3. **Database** – een geschikte database naar keuze (bv. **Postgres**, **MongoDB** of **MySQL**), mag een standaard Docker Hub image zijn, geen eigen image vereist.

De drie onderdelen moeten samenwerken binnen één **Docker Compose** configuratie. De applicaties hoeven niet af te zijn maar er moet wel al commmunicatie bestaan tussen de drie services.

---

## 🧱 Vereisten

### 1. Structuur

- Elk van de drie services (frontend, backend, database) moet in een aparte map staan binnen je project.
  ```
  /frontend
  /backend
  /database
  docker-compose.yml
  dockercompose.md
  ```
- De code moet **functioneel samen werken** (bv. frontend roept backend aan, backend verbindt met database).

---

### 2. Docker Images

- Maak een **Dockerfile** voor de frontend en backend.
- Bouw en test je containers lokaal.
- Publiceer de **frontend**- en **backend**-images op **Docker Hub** onder je eigen account.
  - Naamgevingsconventie:
    - `dockerhub_username/frontend:latest`
    - `dockerhub_username/backend:latest`
- De **database** mag een officiële standaard Docker Hub image gebruiken (bv. `postgres:latest`, `mongo:latest` of `mysql:latest`).

---

### 3. Docker Compose

- Maak een **docker-compose.yml** bestand aan dat:
  - de drie services definieert;
  - gebruik maakt van je gepubliceerde Docker Hub images (frontend en backend);
  - de juiste netwerken en poorten instelt;
  - environment variables bevat (bv. verbinding tussen backend en database);
  - zorgt dat bij `docker compose up` alles automatisch opstart.
  - volg de best practices, bv. geen Backend en DB poorten naar buiten mappen. Zorg ook dat DB toegang geauthenticeerd is.

---

### 4. Documentatie – dockercompose.md

Maak een Markdown-bestand (`dockercompose.md`) met volgende inhoud:

#### 📘 Inhoud:

1. **Korte beschrijving van je drie services**
   - Wat doet elke service?
2. **Docker Hub links**
   - URL’s naar je gepubliceerde images.
3. **Uitleg over je Docker Compose bestand**
   - Welke services staan erin?
   - Hoe communiceren ze?
   - Welke poorten zijn opengezet?
4. **Gebruikte environment variables (indien van toepassing)**
5. **Screenshots:**
   - Terminal-output van een succesvolle `docker compose up`
   - Browserweergave van een werkende applicatie (frontend zichtbaar, eventueel API-test)
6. **Conclusie of reflectie**
   - Wat heb je geleerd of wat waren de uitdagingen?

---

### 5. Versiebeheer (GitHub Classroom)

- Push **alle code** (frontend, backend, docker-compose.yml, dockercompose.md) naar je **officiële GitHub Classroom repository**.
- De code in GitHub moet overeenkomen met de versies waarvan je de images hebt gepusht naar Docker Hub.
- Zorg ook dat alle code gepusht is naar GitHub tegen de deadline.

---

## ✅ Beoordelingscriteria

| Onderdeel                        | Punten | Criteria                                                                                                                                                                                                                            |
| -------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Structuur & werking van services | 0.5    | • Alle drie services (frontend, backend, database) aanwezig in aparte mappen<br>• Services communiceren functioneel (frontend → backend → database)<br>• `docker compose up` start alles zonder handmatige tussenkomst              |
| Dockerfiles & images             | 0.5    | • Dockerfile bouwt zonder errors voor frontend én backend<br>• Beide images gepubliceerd op Docker Hub met correcte naming (`user/frontend:latest`, `user/backend:latest`)<br>• Images zijn publiek toegankelijk                    |
| Docker Compose configuratie      | 0.5    | • Alle drie services correct gedefinieerd met juiste netwerken/poorten<br>• Backend/DB poorten niet naar buiten gemapt; DB-toegang geauthenticeerd<br>• Environment variables correct gebruikt voor service-to-service configuratie |
| Documentatie (dockercompose.md)  | 0.3    | • Beschrijving van elke service + Docker Hub links aanwezig<br>• Screenshots van werkende `docker compose up` en browser/API-test<br>• Reflectie op uitdagingen/leerpunten                                                          |
| GitHub repository                | 0.2    | • Alle code + compose file + documentatie gepusht naar Classroom-repo<br>• Commitgeschiedenis toont incrementele voortgang (niet één grote commit)<br>• Code komt overeen met gepubliceerde image-versies                           |

**Totaal: 2 punten**

---

## ⚙️ Praktische tips

- Test je applicatie eerst lokaal met `docker compose up` voordat je pusht.
- Gebruik `.dockerignore` om onnodige bestanden niet mee te nemen in je image.
- Controleer of je Docker Hub images publiek beschikbaar zijn.
- Voeg eventueel een `.env` bestand toe voor gevoelige variabelen, maar **push dit niet** naar GitHub.

---

## 📅 Deadline

> **maandag 16 november 2026 om 13:59**.
