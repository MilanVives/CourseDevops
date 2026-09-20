# Final Assessment — Devops & Cloud Computing (80%)

> Docker-compose en Minikube worden al apart geëvalueerd via [PE2](2-PE_Compose-Devops.md) en [PE3](3-PE_Minikube-Devops.md) en tellen hier niet opnieuw mee.

Voor het vak Devops & Cloud Computing (V3R316) lever je een eigen project op en verdedig je dit tijdens de examenperiode mondeling (zie [Mondelinge Verdediging](mondelinge-verdediging.md)).

Dit is de laatste stap: je neemt de applicatie die je al hebt gecontaineriseerd (PE2) en lokaal getest op Minikube (PE3), en deployt ze nu **echt naar een Kubernetes-cluster in de cloud**, met productierijpe features zoals secrets management, Helm, meerdere omgevingen en HTTPS.

---

## Weging

- **20%** — PE1 + PE2 + PE3 (permanente evaluatie, al gescoord vóór dit project)
- **80%** — Deze eindopdracht (cloud deployment, analysedossier, mondelinge verdediging)

---

## Stap voor stap

Volg onderstaande stappen in volgorde. Elke stap bouwt verder op de vorige.

### Stap 1 — Bevestig je applicatie

- Standaard gebruik je dezelfde drieservicetoepassing als in PE2/PE3: je **React Native**-app (Cross Platform), je **Java Springboot**-API (Java Backend) en een database.
- **Volg je deze vakken niet, of wil je een andere applicatie gebruiken?** Vraag dan eerst **goedkeuring van de docent** vóór je start. Zonder goedkeuring wordt een afwijkende applicatie niet aanvaard.
- De applicatie zelf wordt niet inhoudelijk geëvalueerd — de deployment, infrastructuur en jouw begrip ervan wel.

### Stap 2 — Zet een Kubernetes-cluster op in de cloud

- Maak een cluster aan bij een cloudprovider naar keuze, manueel of via **Terraform/OpenTofu**.
- Het cluster bevat minstens **drie worker nodes** en een control plane.
- Cloud credits/vouchers voor dit academiejaar: **LINK VOLGT** (niet via GitHub — het aanvraagportaal wordt later gecommuniceerd).

### Stap 3 — Deploy je applicatie naar het cluster

- Gebruik de Docker images die je al gepubliceerd hebt in PE2 (frontend, backend) en een officiële database-image.
- Schrijf Kubernetes manifests (of hergebruik/bouw verder op je manifests uit PE3) voor elke service.
- Test dat de drie services in de cloud met elkaar communiceren, net zoals lokaal in PE3.

### Stap 4 — Secrets management

- Gebruik **Kubernetes Secrets** (of een externe secret manager) voor alles wat gevoelig is: database-wachtwoorden, API keys, tokens.
- Niets gevoelig mag hardgecodeerd staan in een manifest of gecommit worden naar Git.
- De backend/database gebruiken deze secrets via environment variables, niet via hardgecodeerde waarden.

### Stap 5 — Bundel alles in een Helm chart

- Herwerk je manifests tot één herbruikbare **Helm chart**.
- Gebruik `values.yaml` (of losse values-bestanden per omgeving) zodat je dezelfde chart kan hergebruiken voor verschillende omgevingen.

### Stap 6 — Deploy naar meerdere omgevingen

- Deploy je Helm chart naar minstens **twee omgevingen**: test en productie (bv. via aparte namespaces of clusters).
- De omgevingen verschillen enkel via hun `values`-bestand, niet via aparte, losse manifests.

### Stap 7 — Maak de applicatie bereikbaar via HTTPS

Kies één van beide opties (zie [Les 8 – Ingress & Reverse Proxies](../../08-Ingress-and-Reverse-Proxies/)):

- **Optie A — Traefik ingress**: een Traefik ingress controller in je cluster, met automatisch SSL-certificaat.
- **Optie B — Cloudflare tunnel**: een Cloudflare tunnel naar je cluster, met HTTPS via Cloudflare.

In beide gevallen: geen rechtstreeks opengezette node-poorten, en de applicatie moet zonder browserwaarschuwing bereikbaar zijn.

> ⚠️ De VIVES-firewall blokkeert soms niet-standaard HTTP/HTTPS-poorten — hou hier rekening mee bij je opstelling.

### Stap 8 — Automatiseer met een CI/CD pipeline

- Bouw een GitHub Actions workflow die bij een push naar je main branch automatisch **build + deploy** triggert naar de juiste omgeving (test of productie).
- Een falende build/deploy moet zichtbaar falen in GitHub Actions, niet stil vastlopen.

### Stap 9 — Monitoring

- Zet **Prometheus** op om metrics van je cluster/applicatie te verzamelen.
- Bouw een **Grafana**-dashboard met minstens de kernmetrics (bv. CPU, geheugen, aantal requests).

### Stap 10 — Schrijf je analysedossier

Maak een analysedossier (`.md`, `.pdf` of `.tex`) met:

- Korte beschrijving van je applicatie en architectuur.
- Stappenplan van stap 1 t.e.m. 9 hierboven: wat heb je gedaan, en hoe kan iemand anders het reproduceren?
- Screenshots van elke belangrijke stap: cluster, secrets (zonder gevoelige waarden te tonen!), Helm-deploy, ingress/tunnel, CI/CD-run, Grafana-dashboard.
- Motivatie van je keuzes (cloudprovider, Traefik vs. Cloudflare, node-sizing, …).

### Stap 11 — Dien in en houd je live deployment online

- Commit je code **regelmatig** doorheen het project — spreiding en aantal commits tellen mee, niet enkel de eindtoestand.
- Push alles naar de main branch van je GitHub Classroom-repository, **minstens één week vóór het examen**. Enkel de main branch op dat moment wordt geëvalueerd.
- Zet de links naar je live deployment en analysedossier in de `README.md`, en mail ze ook naar de docent.
- Houd je live deployment **10 dagen online**: van één week vóór je mondelinge verdediging tot 3 dagen erna.
- Studenten in tweede zittijd mogen verderwerken op hun repository uit de eerste zittijd.

### Stap 12 — Mondelinge verdediging

- Zie [Mondelinge Verdediging](mondelinge-verdediging.md) voor het volledige format, de voorbeeldvragen en de scoring.
- Duur: 10 à maximum 15 minuten, live demo's aangeraden.
- Standaard op de campus; uitzonderingen enkel na gemotiveerde aanvraag per mail aan de docent.

---

## Evaluatiecriteria

De volgende kenmerken hebben een impact op de evaluatie:

- Volledigheid van het project
- Aanwezigheid van de gevraagde features/tools
- Gebruik van DevOps best practices
- Duidelijkheid en juistheid van de documentatie
- Respecteren van de deadline
- Aantal en spreiding van de commits
- Aangetoond begrip tijdens de mondelinge verdediging (gating-multiplier, zie [Mondelinge Verdediging](mondelinge-verdediging.md))

### Gedetailleerde puntenverdeling (100% van deze opdracht)

| Onderdeel                                       | %   | Criteria                                                                                                                                                                                                                                        |
| ----------------------------------------------- | --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Cloudinfrastructuur                             | 15% | • Cluster met minstens 3 worker nodes + control plane, effectief draaiend<br>• Bij gebruik van Terraform/OpenTofu: reproduceerbaar vanaf nul (`apply`/`destroy` werkt)<br>• Keuzes (provider, node-sizing) beargumenteerd in het analysedossier |
| Live deployment                                 | 10% | • Applicatie is bereikbaar en functioneel op het moment van de verdediging<br>• Alle 3 services draaien en communiceren correct in de cloud (niet enkel lokaal)                                                                                 |
| Secrets management                              | 8%  | • Geen enkele gevoelige waarde hardgecodeerd of gecommit<br>• Secrets correct gebruikt via environment variables in de deployments                                                                                                              |
| Helm chart & environments                       | 12% | • Eén herbruikbare Helm chart, geen hardgecodeerde waarden die per omgeving verschillen<br>• Test- én productie-omgeving beide succesvol deploybaar via `values`-bestanden                                                                      |
| Externe toegang (Traefik of Cloudflare) + HTTPS | 8%  | • Applicatie bereikbaar via HTTPS, geen rechtstreeks opengezette poorten<br>• Certificaat/verbinding werkt zonder browserwaarschuwing                                                                                                           |
| CI/CD pipeline                                  | 12% | • Push naar main triggert een build + deploy zonder manuele tussenkomst<br>• Pipeline faalt zichtbaar en begrijpelijk bij een fout (geen silent failure)<br>• Juiste omgeving (test/productie) wordt getarget                                   |
| Monitoring                                      | 10% | • Prometheus verzamelt metrics van de cluster/applicatie<br>• Grafana-dashboard toont minstens de kernmetrics (bv. CPU/geheugen/requests) leesbaar                                                                                              |
| Documentatie (analysedossier)                   | 15% | • Stappenplan waarmee een derde de deployment kan reproduceren<br>• Screenshots van elke belangrijke stap<br>• Ontwerpkeuzes expliciet gemotiveerd, niet enkel beschreven                                                                       |
| Versiebeheer                                    | 5%  | • Regelmatige commits over de projectperiode, niet geconcentreerd in de laatste dagen<br>• Commit-boodschappen zijn betekenisvol                                                                                                                |
| DevOps best practices                           | 5%  | • Resource limits/requests gezet waar relevant<br>• `.gitignore`/`.dockerignore` correct gebruikt                                                                                                                                               |

> [!WARNING]
> **Totaal: 100%** — dit totaal wordt vervolgens **vermenigvuldigd** met de factor uit de mondelinge verdediging (30% – 100%, zie [Mondelinge Verdediging](mondelinge-verdediging.md)). Een perfecte 100% op bovenstaande tabel die je niet kan uitleggen, levert dus **geen 100% eindscore** op!

> Docker Images, Dockerfile, Docker-compose en Minikube worden hier **niet** opnieuw gescoord — die zitten al in PE1-3.

---

## Mogelijke strafpunten

- **-1 punt per dag** laattijdig indienen (deadline: 7 dagen vóór het examen).
