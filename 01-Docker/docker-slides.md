---
marp: true
theme: gaia
paginate: true
header: 'Les 1 – Docker'
footer: 'DevOps & Cloud Computing'
---

<!-- _class: lead -->

# 🐳 Les 1 — Docker

DevOps & Cloud Computing

Volledige uitgewerkte notities: [docker.md](docker.md)

---

## Agenda

1. Waarom containers?
2. Docker fundamentals
3. Basiscommando's
4. Data & volumes
5. Networking
6. Eigen images & Docker Hub

---

<!-- _class: lead -->

## "It works on my machine!" 🤦

---

## Het probleem

- Applicatie draait lokaal, faalt in test/productie
- Oorzaak: verschillen in OS, libraries, configuratie

```
Laptop ✅  →  Test ❓  →  Productie 💥
```

---

## De oplossing: containers

```
Laptop 📦  →  Test 📦  →  Productie 📦
        (exact dezelfde container)
```

Containers bundelen code + dependencies + runtime → **overal hetzelfde gedrag**.

---

<!-- _class: lead -->

## Docker Fundamentals

---

## Kernbegrippen

| Begrip | Betekenis |
|---|---|
| **Image** | Blueprint waaruit containers starten |
| **Container** | Draaiende instantie van een image |
| **Docker Engine** | Runtime die containers uitvoert |
| **Docker Hub** | Registry om images te delen |

---

## Containers vs VM's

| | Containers | VM's |
|---|---|---|
| Kernel | Gedeeld | Eigen (guest OS) |
| Grootte | MB's | GB's |
| Opstart | Seconden | Minuten |
| Isolatie | Proces-niveau | Volledige hardware |

---

<!-- _class: lead -->

## Basiscommando's

---

## `docker run` — belangrijkste opties

| Optie | Betekenis |
|---|---|
| `-it` | Interactieve terminal |
| `--rm` | Auto-verwijderen na stoppen |
| `--name` | Duidelijke naam |
| `-d` | Achtergrond (detached) |
| `-p host:container` | Poort mappen |
| `-v host:container` | Volume mounten |

---

## Containers beheren

```bash
docker ps [-a]              # (alle) containers
docker stop / rm <naam>     # stoppen / verwijderen
docker inspect <naam>       # volledige details
```

**Detach**: `Ctrl+P` `Ctrl+Q` → `docker attach <naam>` om terug te keren
⚠️ `exit` stopt de container, dat is géén detach!

---

<!-- _class: lead -->

## Data & Volumes

---

## Drie soorten opslag

| Type | Persistent? | Gebruik |
|---|---|---|
| **Ephemeral** | ❌ | Zelden, per ongeluk |
| **Named volume** | ✅ | Productiedata |
| **Bind mount** | ✅ (op host) | Development |

```bash
docker volume create mijnvolume
docker run -v mijnvolume:/data ubuntu
```

---

## `--volumes-from`

Eén "donor"-container deelt **al** zijn volumes met andere containers.

```bash
docker create -v /data --name donor busybox
docker run -d --volumes-from donor --name webapp nginx
```

⚠️ Gebruik **named volumes** in de donor, anders verdwijnt de data bij `docker rm`!

---

<!-- _class: lead -->

## Networking

---

## Bridge netwerk & poorten

```bash
docker run -d -p 8080:80 nginx
```

`8080` (host) → `80` (container, waar nginx luistert)

```bash
docker network create mijnnet
docker run -dit --name c1 --network mijnnet ubuntu
docker run -dit --name c2 --network mijnnet ubuntu
docker exec -it c1 ping c2   # containers zien elkaar via naam
```

---

<!-- _class: lead -->

## Eigen Images & Docker Hub

---

## `docker commit` flow

```
base image → docker run → wijzigen → docker commit → nieuwe image
```

```bash
docker run -it ubuntu bash
echo "hallo" > /hallo.txt && exit
docker commit <container_id> mijnimage:v1
```

---

## Publiceren

```bash
docker login
docker tag mijnimage:v1 user/mijnimage:v1
docker push user/mijnimage:v1
```

→ iedereen kan nu `docker pull user/mijnimage:v1`

---

<!-- _class: lead -->

## Samenvatting

- Containers = lichtgewicht, snel, portable
- `-it --rm --name -d -p -v` zijn je basisopties
- Named volumes voor data, bridge netwerk voor communicatie
- `commit` → `tag` → `push` om te publiceren

**Volgende les: Dockerfile & Docker Compose**

---

<!-- _class: lead -->

# Vragen?
