# Docker Compose Overview Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                 Before Docker Compose                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  docker network create foodapp-network                     │
│  docker run -d --name mongodb --network foodapp-network... │
│  docker build -t backend ./api                             │
│  docker run -d --name backend --network foodapp-network... │
│  docker build -t frontend ./frontend                       │
│  docker run -d --name frontend --network foodapp-network...│
│                                                             │
│  🔥 Complex, error-prone, hard to remember                 │
└─────────────────────────────────────────────────────────────┘

                            ↓

┌─────────────────────────────────────────────────────────────┐
│                 With Docker Compose                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                   docker compose up                        │
│                                                             │
│  ✅ Simple, reliable, reproducible                          │
│  ✅ One command for entire stack                            │
│  ✅ Version controlled configuration                        │
│  ✅ Easy collaboration                                      │
└─────────────────────────────────────────────────────────────┘
```

This diagram should be replaced with an actual image file.