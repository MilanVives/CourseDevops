# Multi-Container Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Stack                     │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Frontend   │    │   Backend    │    │   MongoDB    │  │
│  │   (nginx)    │    │  (Node.js)   │    │  (Database)  │  │
│  │              │    │              │    │              │  │
│  │ Port: 8080   │    │ Port: 3000   │    │ Port: 27017  │  │
│  │              │    │              │    │ (internal)   │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│          │                    │                    │        │
│          │                    │                    │        │
│          └────────────────────┼────────────────────┘        │
│                               │                             │
│                    ┌──────────▼──────────┐                 │
│                    │  Auto-created       │                 │
│                    │  Docker Network     │                 │
│                    │  (Service Discovery)│                 │
│                    └─────────────────────┘                 │
│                                                             │
│  External Access:                                           │
│  • Frontend: http://localhost:8080                         │
│  • Backend API: http://localhost:3000                      │
│  • Database: Internal only (secure)                        │
└─────────────────────────────────────────────────────────────┘
```

This diagram should be replaced with an actual image file.