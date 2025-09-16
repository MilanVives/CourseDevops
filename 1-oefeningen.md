# Docker Les 1 – Oefenbundel

## Oefenvragen

### Vraag 1  
Wat is het verschil tussen een **image** en een **container**?

---  
### Vraag 2  
Wat doet de optie `--rm` bij `docker run`?

---  
### Vraag 3  
Je start een container met:  
```bash
docker run -it --name web ubuntu bash
```
Wat gebeurt er en wat is de rol van `--name`?

---  
### Vraag 4  
Wat gebeurt er met data in een container wanneer je die container verwijdert?

---  
### Vraag 5  
Leg uit wat het verschil is tussen een **ephemeral volume**, een **named volume**, en een **bind mount**.

---  
### Vraag 6  
Je start een Nginx-container met:  
```bash
docker run -d -p 8080:80 nginx
```
Wat betekenen de poortnummers?

---  
### Vraag 7  
Hoe kan je zien welk IP-adres een container heeft?

---  
### Vraag 8  
Je hebt twee containers in hetzelfde custom netwerk. Hoe kan container A container B bereiken?

---  
### Vraag 9  
Wat is het verschil tussen **detached mode** en **attached mode**?

---  
### Vraag 10  
Hoe maak je van een container waar je een bestand in hebt toegevoegd een nieuwe image?

---  

## Oplossingen

### Antwoord 1  
- **Image** = blueprint (read-only sjabloon) dat beschrijft wat er in de container zit.  
- **Container** = een draaiende instantie van een image (runtime).  

### Antwoord 2  
- De container wordt **automatisch verwijderd** zodra hij stopt.  
- Handig voor tijdelijke containers die je niet wil bewaren.  

### Antwoord 3  
- Start een interactieve Ubuntu-container met bash.  
- `--name web` geeft de container een vaste naam → makkelijker te beheren i.p.v. lange ID’s.  

### Antwoord 4  
- Data die **alleen binnen de container** staat → verdwijnt.  
- Data in **named volumes** → blijft bestaan.  
- Data in **bind mounts** → blijft op de host.  

### Antwoord 5  
- **Ephemeral volume**: anoniem, verdwijnt automatisch bij verwijderen container.  
- **Named volume**: door Docker beheerde opslag, blijft bestaan totdat expliciet verwijderd.  
- **Bind mount**: koppelt een directory van de host aan de container.  

### Antwoord 6  
- `8080` = poort van de **host**.  
- `80` = poort binnen de **container** waar Nginx luistert.  
- Je bereikt de webserver via `http://localhost:8080`.  

### Antwoord 7  
- Gebruik:  
  ```bash
  docker inspect <container_id>
  ```  
- Zoek in de JSON naar `.NetworkSettings.IPAddress`.  

### Antwoord 8  
- Via de **container name** van B.  
- Voorbeeld: `ping b` of verbinding via `http://b:poort`.  

### Antwoord 9  
- **Attached**: de container draait in de huidige terminal, je ziet de output.  
- **Detached**: de container draait op de achtergrond (`-d`).  

### Antwoord 10  
1. Start container en voeg bestand toe.  
2. Stop container.  
3. Maak nieuwe image:  
   ```bash
   docker commit <container_id> mijnimage:v1
   ```  
