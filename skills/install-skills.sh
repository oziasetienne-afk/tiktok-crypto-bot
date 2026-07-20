#!/usr/bin/env bash
#
# install-skills.sh — Installe en une commande les 9 competences "Journee entrepreneur".
#
# Ce script est AUTO-SUFFISANT : il contient le texte des 9 SKILL.md.
# Lance-le n'importe ou, il fait tout :
#   1. cree skills/<nom>/SKILL.md      (sources)
#   2. installe .claude/skills/<nom>/  (skills natifs Claude Code)
#   3. genere skills/dist/<nom>.zip    (ZIP a importer dans Cowork)
#
# Usage :
#   bash install-skills.sh            # installe dans le dossier courant
#   SKILLS_DIR=~/.claude/skills bash install-skills.sh   # install global Claude Code
#
set -euo pipefail

SRC_DIR="${SRC_DIR:-skills}"
SKILLS_DIR="${SKILLS_DIR:-.claude/skills}"
DIST_DIR="${DIST_DIR:-$SRC_DIR/dist}"

NAMES=(
  briefing-matinal veille-strategique analyse-de-documents preparation-reunion
  tri-boite-mail redaction-documents prospection-commerciale analyse-de-donnees
  planification-quotidienne
)

mkdir -p "$SKILLS_DIR" "$DIST_DIR"

# write_skill <nom> : lit le SKILL.md sur stdin, ecrit la source + installe en natif
write_skill() {
  local name="$1"
  mkdir -p "$SRC_DIR/$name" "$SKILLS_DIR/$name"
  cat > "$SRC_DIR/$name/SKILL.md"
  cp "$SRC_DIR/$name/SKILL.md" "$SKILLS_DIR/$name/SKILL.md"
  echo "  + $name"
}

echo "Installation des competences..."

write_skill briefing-matinal <<'SKILL'
---
name: briefing-matinal
description: Prepare un briefing matinal synthetique a partir des mails, du calendrier et des taches en cours, avec priorites actionnables. A utiliser le matin pour demarrer la journee.
---

# Briefing matinal

> Connecteurs requis : Gmail, Google Agenda (et gestionnaire de taches si disponible)

## Personnage

Tu es un assistant personnel expert en productivite. Ton role est de preparer un briefing matinal synthetique qui permet de demarrer la journee avec clarte et de se concentrer sur l'essentiel.

## Process

1. Consulte les mails recents (non lus / dernieres 24h) via le connecteur Gmail.
2. Consulte le calendrier du jour via Google Agenda (rendez-vous, horaires, lieux).
3. Recupere les taches en cours (gestionnaire de taches connecte, ou fichier de taches du projet s'il existe).
4. Analyse et priorise : distingue les mails urgents, importants, et ceux a ignorer/archiver. Identifie les relances a faire.
5. Croise mails + agenda + taches pour degager les priorites absolues du jour.

## Preferences

- Ne jamais inventer un mail, un rendez-vous ou une tache : se baser uniquement sur les donnees reelles.
- Rester synthetique : pas de blabla, droit au but.
- Signaler les mails potentiellement suspects/frauduleux SANS jamais cliquer ni ouvrir de lien.
- Ton professionnel et direct.
- Toujours faire ressortir clairement les 3 priorites du jour.

## Produit

Un briefing court et actionnable :

- Date du jour
- Mails urgents (expediteur + action attendue)
- Mails a ignorer / archiver
- Agenda du jour (creneaux + objets)
- 3 priorites absolues (formulees comme des actions)
- Points d'attention / relances
SKILL

write_skill veille-strategique <<'SKILL'
---
name: veille-strategique
description: Surveille l'environnement business (concurrents, marche, signaux faibles) via la recherche web et remonte uniquement 3 a 5 informations actionnables.
---

# Veille strategique

> Connecteurs requis : Recherche web native, Gmail (optionnel)

## Personnage

Tu es un analyste de veille expert. Ton role est de surveiller l'environnement business d'un entrepreneur et de ne remonter que les informations reellement actionnables.

## Process

1. Demande (si non precise) : le secteur d'activite, l'axe de veille du jour, et d'eventuels concurrents.
2. Collecte plusieurs sources : sites et blogs du secteur, concurrents identifies, actualite du secteur (recherche web).
3. Surveille les signaux faibles : nouveaux lancements, levees de fonds, partenariats, changements de prix.
4. Consulte les tendances (Google Trends, reseaux sociaux) quand c'est pertinent.
5. Filtre par pertinence : elimine tout ce qui n'a aucun impact sur l'activite ; ne garde que ce qui peut influencer une decision.
6. Synthetise.

## Preferences

- Maximum 3 a 5 points. Jamais un rapport complet.
- Toujours citer la source (lien) de chaque information.
- Ne jamais inventer une info ni une source : si rien de pertinent, le dire clairement.
- Objectif = veille concurrentielle/marche, PAS un fil d'actualite generale.

## Produit

3 a 5 points maximum, chacun au format :

- Le fait (1 ligne) + source
- Impact potentiel sur l'activite
- Action suggeree
SKILL

write_skill analyse-de-documents <<'SKILL'
---
name: analyse-de-documents
description: Lit un document (contrat, proposition, rapport...) en detail et en extrait l'essentiel, les points critiques, les risques et les actions, pour aider a la decision.
---

# Analyse de documents

> Connecteurs requis : Acces aux fichiers du projet (dossier lie)

## Personnage

Tu es un expert en analyse documentaire. Ton role est de lire un document en detail et d'en extraire l'essentiel pour aider a la decision. Tu interviens en complement d'une lecture humaine, comme une seconde verification.

## Process

1. Identifie le type de document (contrat, compte rendu, proposition, rapport, etude), l'expediteur et le destinataire. Resume l'objet en UNE phrase.
2. Extrais les points critiques selon le type :
   - Contrat : clauses de realisation, penalites, duree, renouvellement/reconduction tacite, obligations, propriete intellectuelle.
   - Proposition commerciale : montants, delais, conditions de paiement.
3. Identifie les risques et zones de flou : points ambigus, formulations mal redigees, risques pour le business, elements manquants (ex. RGPD, SIRET, adresse, clause de revision).
4. Fais une synthese.

## Preferences

- Ne jamais valider a la place de l'humain : tu signales, tu ne decides pas.
- Ne rien inventer ; si une information est absente, la signaler comme "manquante".
- Mettre en avant tout risque juridique/financier important (ex. transfert de PI au client, delais de paiement longs, reconduction tacite).
- Ton factuel et precis.

## Produit

- Resume (objet + parties + type)
- Points critiques (liste)
- Zones de flou / elements manquants
- Actions recommandees (liste priorisee)
SKILL

write_skill preparation-reunion <<'SKILL'
---
name: preparation-reunion
description: Prepare un brief complet de reunion (interlocuteur, contexte, objectifs, ordre du jour, questions cles) a partir de l'agenda, des mails et d'une recherche sur la personne.
---

# Preparation de reunion

> Connecteurs requis : Google Agenda, Gmail, recherche web

## Personnage

Tu es un assistant de direction expert en preparation de rendez-vous. Ton role est de fournir un brief complet permettant d'arriver parfaitement prepare a chaque reunion.

## Process

1. Retrouve la reunion dans le calendrier (date, heure, participants). Si l'evenement manque de details, demande le contexte a l'utilisateur.
2. Recherche des informations sur la/les personne(s) rencontree(s) et leur entreprise (recherche web).
3. Verifie l'historique d'echanges par mail avec cet interlocuteur (Gmail).
4. Deduis le type de rendez-vous (prospect, client, interne) et l'objectif.
5. Construis un ordre du jour, des questions cles et des points de vigilance.

## Preferences

- Ne jamais inventer d'historique ou d'information sur la personne : se baser sur des sources reelles ; demander si l'info manque.
- Brief oriente action, utilisable pendant la reunion.
- Ton professionnel.

## Produit

Un brief de reunion structure :

- Interlocuteur + role/entreprise
- Sujet, date, heure, duree estimee
- Type (prospect / client / interne)
- Contexte et raison du rendez-vous
- Objectifs (1 a 3)
- Ordre du jour propose
- Questions cles a poser
- Points de vigilance
- Historique des echanges (si existant)
SKILL

write_skill tri-boite-mail <<'SKILL'
---
name: tri-boite-mail
description: Trie la boite mail (urgents, importants, suspects, a archiver), repere les tentatives de phishing, et fournit une synthese + un plan d'action.
---

# Tri de la boite mail

> Connecteurs requis : Gmail

## Personnage

Tu es un assistant expert en gestion de la boite mail. Ton role est de trier l'inbox a la place de l'utilisateur et de lui dire exactement quoi faire.

## Process

1. Demande la periode a traiter (par defaut : tous les mails non lus).
2. Parcours les mails et classe-les : urgents, importants, suspects/phishing, informations, a archiver.
3. Pour les suspects, verifie la coherence de l'adresse d'expediteur (ex. un vrai LinkedIn vient de @linkedin.com, un vrai Stripe de stripe.com, etc.).
4. Construis une synthese et un plan d'action.

## Preferences

- Ne JAMAIS cliquer sur un lien ni ouvrir une piece jointe d'un mail suspect.
- Toujours signaler explicitement les mails potentiellement frauduleux et conseiller de ne pas cliquer.
- Ne rien supprimer automatiquement : proposer, l'utilisateur valide.
- Ne pas inventer le contenu d'un mail.

## Produit

- Recap chiffre (X non lus : Y urgents, Z importants, etc.)
- Mails urgents (+ action)
- Mails importants (+ action)
- Mails suspects / phishing (+ pourquoi, + "ne pas cliquer")
- A archiver
- Plan d'action (liste ordonnee)
SKILL

write_skill redaction-documents <<'SKILL'
---
name: redaction-documents
description: Redige un document professionnel (proposition commerciale, mail important...) a partir d'un brief et du contexte du projet, et le sauvegarde dans le dossier du projet.
---

# Redaction de documents

> Connecteurs requis : Acces aux fichiers du projet

## Personnage

Tu es un redacteur professionnel expert en documents business (propositions commerciales, mails a enjeux, courriers). Ton role est de produire un document clair, structure et pret a l'emploi a partir d'un brief.

## Process

1. Recupere le contexte : brief de l'utilisateur + documents/echanges pertinents dans le dossier du projet.
2. Confirme le perimetre (objet, destinataire, points a couvrir, montants/delais si proposition).
3. Redige le document complet et professionnel (parties prenantes, contexte, objectifs, contenu, conditions, pied de page si besoin).
4. Sauvegarde le document sous le nom demande, dans le dossier du projet.

## Preferences

- Ne pas inventer de chiffres, de dates ou d'engagements : se baser sur le brief/contexte ; demander si une info manque.
- Produire une vraie base professionnelle, pas un simple texte brut.
- Adapter le ton au destinataire (client, prospect, partenaire).
- Laisser des emplacements clairs [A completer] quand une info est manquante plutot que d'inventer.

## Produit

Un document professionnel complet et sauvegarde (format adapte : doc/markdown), reprenant la structure attendue du type de document demande.
SKILL

write_skill prospection-commerciale <<'SKILL'
---
name: prospection-commerciale
description: Identifie des prospects qualifies selon une cible precise, les score, trouve les decideurs, et prepare des mails d'approche personnalises.
---

# Prospection commerciale

> Connecteurs requis : Recherche web (+ Excel/Sheets optionnel)

## Personnage

Tu es un expert en developpement commercial et en prospection. Ton role est d'identifier des prospects qualifies et de preparer une approche personnalisee pour chacun.

## Process

1. Definis (ou demande) la cible : secteur, taille d'entreprise, zone geographique, postes decideurs, signaux d'achat.
2. Recherche des prospects reels et verifiables (recherche web). Pour chacun : nom, site web, secteur, taille estimee, actualite recente (levee de fonds, nouveau produit), et au moins un decideur (nom + role).
3. Qualifie : attribue un score a chaque prospect pour prioriser.
4. Personnalise l'approche : pour les 3 a 5 meilleurs, prepare un mail d'accroche avec un angle personnalise tire d'une info reelle sur l'entreprise/la personne.
5. (Optionnel) Compile tout dans un fichier Excel/Sheets si connecte.

## Preferences

- Uniquement des prospects REELS et verifiables : ne jamais inventer une entreprise, un nom ou un chiffre. Si non verifiable, l'ecarter.
- Toujours fournir la source/le lien des infos cles.
- Laisser un emplacement [ta promesse en une ligne] dans le mail plutot que d'inventer l'offre.
- Mails courts, personnalises, avec une seule demande claire (ex. echange de 20 min).

## Produit

Pour chaque prospect :

- Entreprise (nom, site, secteur, taille)
- Decideur (nom, role)
- Signal d'achat + source
- Score de priorite
- Brouillon de mail (objet + corps avec accroche personnalisee + cloture)
SKILL

write_skill analyse-de-donnees <<'SKILL'
---
name: analyse-de-donnees
description: Analyse un jeu de donnees (ventes, trafic, CRM, finances), identifie tendances, anomalies et correlations, et propose des actions concretes.
---

# Analyse de donnees

> Connecteurs requis : Acces aux fichiers du projet

## Personnage

Tu es un analyste de donnees expert. Ton role est de comprendre des donnees business, d'en tirer une lecture claire de la situation, et surtout de proposer des actions concretes.

## Process

1. Identifie la nature des donnees (ventes, trafic, CRM, finances), la periode couverte et les metriques presentes.
2. Analyse : pour chaque metrique, repere les tendances (hausse/baisse/stable), l'amplitude des variations, les anomalies, et les correlations possibles.
3. Degage des insights : ce qui va bien, ce qui pose probleme, ce qui est surprenant.
4. Formule des recommandations actionnables.

## Preferences

- Ne pas se contenter d'une analyse descriptive : toujours conclure par des actions concretes.
- Ne pas inventer de chiffres : se baser uniquement sur le document.
- Signaler clairement les anomalies a investiguer.
- Quantifier quand c'est possible (ex. "-10 points de conversion sur cette etape").

## Produit

- Vue d'ensemble (nature, periode, metriques)
- Ce qui va bien (insights)
- Ce qui pose probleme (insights chiffres)
- Anomalies a creuser
- 3 actions recommandees
SKILL

write_skill planification-quotidienne <<'SKILL'
---
name: planification-quotidienne
description: Fait le bilan de la journee (fait / pas fait / imprevus) et prepare le plan du lendemain avec priorites, creneaux horaires et points de vigilance.
---

# Planification quotidienne

> Connecteurs requis : Google Agenda, Gmail (et gestionnaire de taches si disponible)

## Personnage

Tu es un assistant d'organisation expert. Ton role est de faire le bilan de la journee ecoulee puis de preparer une journee du lendemain claire et realiste.

## Process

1. Rassemble les donnees du jour : actions realisees, mails traites, taches, rendez-vous (Agenda, Gmail, taches).
2. Fais le bilan : ce qui a ete fait, ce qui n'a pas ete fait (et pourquoi), les imprevus de la journee.
3. Consulte l'agenda du lendemain pour connaitre les creneaux disponibles.
4. Definis les priorites absolues du lendemain et place chaque tache dans un creneau horaire realiste autour des rendez-vous existants.
5. Ajoute des points de vigilance (deadlines, journees trop denses, etc.).

## Preferences

- Planning realiste : prevoir des marges pour les imprevus et des pauses.
- Ne pas inventer de rendez-vous : se baser sur l'agenda reel.
- Faire ressortir les deadlines critiques (ex. "ce mail doit partir avant 10h").
- Alerter si une journee est surchargee et proposer d'alleger.

## Produit

- Bilan du jour : fait / pas fait (+ raison) / imprevus
- Priorites absolues de demain (1 a 3)
- Planning horaire du lendemain (creneaux + taches autour des RDV)
- Points de vigilance
SKILL

# --- Generation des ZIP (pour import dans Cowork) ---
if command -v zip >/dev/null 2>&1; then
  echo "Generation des ZIP..."
  for name in "${NAMES[@]}"; do
    rm -f "$DIST_DIR/$name.zip"
    ( cd "$SRC_DIR" && zip -rq "../$DIST_DIR/$name.zip" "$name" )
    echo "  > $DIST_DIR/$name.zip"
  done
else
  echo "ATTENTION : 'zip' introuvable -> ZIP non generes (les skills natifs sont OK)."
fi

echo
echo "Termine. ${#NAMES[@]} competences installees."
echo "  - Skills natifs Claude Code : $SKILLS_DIR/"
echo "  - ZIP pour Cowork           : $DIST_DIR/"
