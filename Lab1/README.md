# Lab 1 - Bazele Docker

## Ce inveti
- Instalarea si verificarea Docker
- Diferenta dintre imagini si containere
- Construirea de imagini custom cu Dockerfile
- Maparea porturilor si rularea in background
- Publicarea imaginilor pe Docker Hub
- Networking intre containere (bridge default vs custom)
- Persistenta datelor cu volume

## Structura

```
Lab1/
├── Dockerfile          # Definitia imaginii custom (aplicatie Python Flask)
├── app.py              # Aplicatia web Flask
├── requirements.txt    # Dependinte Python
├── templates/
│   └── index.html      # Template HTML pentru aplicatie
└── cheatsheet.md       # Ghid pas-cu-pas cu explicatii
```

## Pornire rapida

```bash
# Build si rulare aplicatia Flask
docker build -t testapp .
docker run -d -p 8888:5000 testapp

# Deschide http://localhost:8888 in browser
```

## Ghid complet

Vezi [cheatsheet.md](cheatsheet.md) pentru ghidul complet cu explicatii detaliate.
