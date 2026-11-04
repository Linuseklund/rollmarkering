# Rollmarkering

Ett verktyg för att markera vem som är vem och vad som är vad i ett bildmanus eller en animatic. Du lägger in character- och prop-sheets, tar in storyboardbilder eller video och markerar rollerna. Resultatet blir en rollkarta (CAST MAP) till Higgsfield/Seedance och kan skickas vidare till Scenplanering.

## Delar

| Fil | Vad |
|---|---|
| `web/` | Själva programmet (en HTML-fil). Publiceras som webbsida på Vercel. |
| `main.swift` | Mac-programmet: ett fönster runt `web/` som sparar projekt och bilder i en vald mapp. |
| `icon.swift`, `ikon.png` | Programikonen. |
| `bygg.sh` | Bygger om `Rollmarkering.app` i mappen ovanför. |

## Webbversionen

På webben sparas projekten i webbläsaren (localStorage). Exportera projektfilen för att flytta den mellan datorer.

Vercel: rotkatalog `web`, inget byggsteg.
