# Competences "Journee entrepreneur" (Cowork / Claude Skills)

Ce dossier contient 9 competences pretes a importer dans Cowork (Claude).
Chaque competence a son propre dossier avec un `SKILL.md`, et un ZIP correspondant
dans `dist/` dont la **racine est le dossier de la competence** (pas de sous-dossier).

## Les 9 competences

| # | Dossier | ZIP | Connecteurs requis |
|---|---------|-----|--------------------|
| 1 | `briefing-matinal/` | `dist/briefing-matinal.zip` | Gmail, Google Agenda |
| 2 | `veille-strategique/` | `dist/veille-strategique.zip` | Recherche web (Gmail opt.) |
| 3 | `analyse-de-documents/` | `dist/analyse-de-documents.zip` | Acces aux fichiers |
| 4 | `preparation-reunion/` | `dist/preparation-reunion.zip` | Google Agenda, Gmail, recherche web |
| 5 | `tri-boite-mail/` | `dist/tri-boite-mail.zip` | Gmail |
| 6 | `redaction-documents/` | `dist/redaction-documents.zip` | Acces aux fichiers |
| 7 | `prospection-commerciale/` | `dist/prospection-commerciale.zip` | Recherche web (Excel/Sheets opt.) |
| 8 | `analyse-de-donnees/` | `dist/analyse-de-donnees.zip` | Acces aux fichiers |
| 9 | `planification-quotidienne/` | `dist/planification-quotidienne.zip` | Google Agenda, Gmail |

## Comment installer une competence dans Cowork

1. Recupere le fichier ZIP de la competence (depuis `dist/`).
2. Dans Cowork : **Personnaliser > Competences > "+" > Creer un skill > Importer le ZIP**.
3. Verifie que la competence apparait dans **Personnaliser > Competences** (activee).
4. Repete pour la competence suivante.

## Pre-requis (a verifier dans Cowork)

- **Execution de code et creation de fichiers** : Reglages > Capacites (interrupteur a activer).
- **Connecteurs** : Gmail, Google Agenda, Recherche web, Acces aux fichiers.
  Les competences qui en dependent demanderont les infos a la main si le connecteur manque.
- **Projet** : creer un projet "Journee entrepreneur" lie a un dossier local pour tes documents.

> Note : il existe aussi un 10e agent (transcription d'appels) prevu pour le terminal /
> Claude Code, hors de cette installation Cowork. A mettre en place separement.
