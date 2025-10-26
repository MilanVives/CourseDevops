# Service Name Resolution Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                Docker Compose Network                       │
│                                                             │
│  ┌──────────────┐                        ┌──────────────┐  │
│  │   Backend    │                        │   MongoDB    │  │
│  │              │                        │              │  │
│  │ Container IP │ ◄─── DNS Query ────►   │ Container IP │  │
│  │ 172.18.0.2   │      "mongodb"         │ 172.18.0.3   │  │
│  │              │                        │              │  │
│  │ Code:        │                        │ Service:     │  │
│  │ mongodb://   │                        │ "mongodb"    │  │
│  │ mongodb:27017│                        │              │  │
│  └──────────────┘                        └──────────────┘  │
│                                                             │
│           ┌─────────────────────────────────┐              │
│           │     Docker Internal DNS         │              │
│           │     (127.0.0.11)               │              │
│           │                                 │              │
│           │ Service Name → IP Resolution:   │              │
│           │ • mongodb → 172.18.0.3         │              │
│           │ • backend → 172.18.0.2         │              │
│           │ • frontend → 172.18.0.4        │              │
│           └─────────────────────────────────┘              │
│                                                             │
│  Key Benefits:                                              │
│  ✅ No hardcoded IP addresses                              │
│  ✅ Automatic resolution on container restart              │
│  ✅ Human-readable service names                           │
│  ✅ Works across different environments                    │
└─────────────────────────────────────────────────────────────┘
```

This diagram should be replaced with an actual image file.