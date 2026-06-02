# Message a coller dans Cowork

> Avant d'envoyer : joins le fichier `install-skills.sh` a la conversation Cowork
> (celui genere par ce projet). Puis colle tout ce qui suit la ligne >>>>> et envoie.

>>>>>

Tu es Claude dans Cowork, sur mon PC. Je suis sur mon telephone et je te regarde : agis a ma place quand tu peux, et ne me demande un clic que si c'est indispensable. Avance UNE competence a la fois.

CONTEXTE : je t'ai joint un script `install-skills.sh`. Il est auto-suffisant : il contient le texte des 9 competences "Journee entrepreneur" et genere leurs ZIP.

ETAPE 0 - Verifications (fais-les puis dis-moi le resultat)
1. Verifie que "Execution de code et creation de fichiers" est active (Reglages > Capacites). Si tu ne peux pas l'activer toi-meme, dis-le-moi, je le fais (c'est juste un interrupteur).
2. Dis-moi quels connecteurs sont actifs et lesquels manquent : Gmail, Google Agenda, recherche web, acces aux fichiers.
3. Cree un projet nomme "Journee entrepreneur" lie a un dossier local ou je mettrai mes documents.

ETAPE 1 - Generer les competences
- Execute le script `install-skills.sh` que je t'ai joint. Il cree, dans le dossier de travail :
  - `skills/<nom>/SKILL.md` (les 9 sources)
  - `skills/dist/<nom>.zip` (les 9 ZIP a importer, racine = dossier de la competence)
- Confirme-moi que les 9 ZIP sont bien generes (liste-les).

ETAPE 2 - Installer les competences, UNE A LA FOIS, dans cet ordre :
briefing-matinal, veille-strategique, analyse-de-documents, preparation-reunion, tri-boite-mail, redaction-documents, prospection-commerciale, analyse-de-donnees, planification-quotidienne.

Pour chaque competence :
a) Ouvre Personnaliser > Competences > "+" > Creer un skill > Importer le ZIP, et importe le ZIP correspondant depuis `skills/dist/`.
   - Si tu disposes du Computer Use, fais ces clics toi-meme.
   - Sinon, prepare le ZIP et guide-moi clic par clic (je suis sur mon tel, instructions simples).
b) Confirme-moi que la competence apparait bien dans Personnaliser > Competences (activee), puis passe a la suivante.

ETAPE 3 - A la fin
- Teste un agent : demande-toi a toi-meme "Fais-moi le brief matinal" et montre-moi le rendu (si Gmail/Agenda manquent, indique-le, ne l'invente pas).
- Fais un recap : competences installees / connecteurs manquants / ce qu'il reste a faire.

REGLES : ne rien inventer ; une competence a la fois ; me demander un clic uniquement si indispensable ; ne pas modifier le contenu des SKILL.md generes par le script.
