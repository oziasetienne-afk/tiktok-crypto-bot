# Daily TikTok Crypto — bot gratuit & pérenne (GitHub Actions)

Chaque jour à ~9h (Paris), ce bot génère pour toi une vidéo TikTok crypto prête à poster :

**RSS crypto** (CoinDesk + CryptoNews + Decrypt) → article le plus « viral » → **script TikTok FR**
(GitHub Models, gratuit) → **voix off FR** (edge-tts) avec timings mot-à-mot → **vidéo verticale
dynamique** (ffmpeg) : fond animé + vrai graphique des cryptos qui montent/chutent (CoinGecko) +
sous-titres animés synchronisés à la voix (style TikTok) → vidéo commitée dans `video/<date>.mp4`
→ **Issue GitHub** qui te mentionne (donc **email automatique**) avec le lien de téléchargement et
la légende à copier.

Tu télécharges la vidéo et tu la postes toi-même en 10 s : **0 €**, pas de serveur, pas de ban,
rien qui expire.

## Pourquoi c'est 100 % gratuit et sans clé API

Tout tourne avec le `GITHUB_TOKEN` fourni automatiquement par GitHub Actions :

- **Le script** est écrit via **GitHub Models** (inférence gratuite, incluse dans Actions).
- **La voix** est synthétisée par **edge-tts** (gratuit, pas de clé).
- **Les données marché** viennent de l'**API publique CoinGecko** (gratuite, pas de clé).
- **La notification** passe par une **Issue GitHub** qui te `@mentionne` → GitHub t'envoie l'email.

👉 **Aucun secret à configurer.** Pas de clé Anthropic, ElevenLabs ou Gmail.

## Mise en route (une seule fois)

1. **Vérifie que GitHub Models est activé** pour ton compte/organisation
   (Settings → Models, ou simplement lance le workflow : s'il échoue sur l'appel modèle, c'est ça).
2. **Teste** : onglet `Actions` → « Daily TikTok Crypto Script » → **Run workflow**.
   Tu reçois l'Issue (et l'email) en ~1 à 2 min, avec le lien de la vidéo et la légende.

Le cron tourne ensuite tout seul chaque jour.
(`07:00 UTC` = 9h Paris l'été, 8h l'hiver — ajustable dans `.github/workflows/daily-tiktok.yml`.)

## Personnalisation (en haut de `daily_tiktok.py`)

| Variable | Rôle |
|----------|------|
| `RSS_FEEDS` | Les sources d'actu crypto. |
| `HASHTAGS` | Les hashtags ajoutés en fin de légende. |
| `HANDLE` / `TOP_LABEL` | Le pseudo et le bandeau affichés dans la vidéo. |
| `VOICE_EVEN` / `VOICE_ODD` | Les voix edge-tts alternées jour pair / impair. |
| `SHOCK_WORDS` | Les mots qui font monter le score de « viralité » d'un article. |

## Robustesse

- Les **articles en double** entre les 3 flux RSS sont dédoublonnés.
- Le **score de viralité** prend en compte le titre *et* le résumé.
- Les appels **GitHub Models** et **CoinGecko** sont **réessayés** (backoff 2s/4s/8s) en cas
  d'erreur réseau ou de rate-limit.
- Si la **voix** ou la **vidéo** échoue, l'Issue est quand même créée avec le script à copier.
- Si tout plante, une **Issue d'erreur** te mentionne avec la trace complète.

## Fichiers

- `daily_tiktok.py` — le script complet (RSS → script → voix → vidéo → Issue).
- `.github/workflows/daily-tiktok.yml` — le planificateur (cron + bouton « Run workflow »).
- `requirements.txt` — dépendances Python (`requests`, `feedparser`, `edge-tts`, `Pillow`,
  `faster-whisper`).
- `video/` — les vidéos générées, une par jour.
