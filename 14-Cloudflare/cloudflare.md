# Les 14 – Cloudflare

> 🚧 **Placeholder** — inhoud nog te schrijven.

## 🎯 Doel van de les

Studenten leren hoe ze Cloudflare inzetten om hun eigen applicaties (uit PE2/PE3/Final Assessment) veilig en betrouwbaar publiek bereikbaar te maken, als alternatief of aanvulling op een klassieke ingress-controller.

## 🧩 Onderwerpen

- **Tunneling**: Cloudflare Tunnel opzetten naar een lokaal of cloud-cluster, zonder open inbound poorten.
- **App Security**: WAF-regels, rate limiting, DDoS-bescherming, bot-mitigatie.
- **App Login (Zero Trust Access)**: toegang tot interne/staging-applicaties beveiligen met Cloudflare Access (identity-based login, zonder VPN).
- **App Deployment**: DNS, SSL/TLS-certificaten, Cloudflare Pages voor statische frontends.
- **Workers**: serverless functies op de Cloudflare edge (bv. voor lichte API-logica, redirects, A/B-testing).

## 🔗 Links met andere lessen

- Bouwt verder op [Les 8 – Ingress & Reverse Proxies](../08-Ingress-and-Reverse-Proxies/) (Cloudflare Tunnel als alternatief voor Traefik/Nginx ingress).
- Relevant voor de [Final Assessment](../00-Assessment/Devops/4-Final-Assessment.md) (Stap 7: externe toegang via Traefik of Cloudflare).
