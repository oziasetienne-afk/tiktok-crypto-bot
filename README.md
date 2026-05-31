# Daily TikTok Crypto — bot gratuit & pérenne (GitHub Actions)

Remplace le **Pipeline 1 n8n** (qui expire). Chaque jour à ~9h (Paris), ce bot :
RSS crypto (CoinDesk + CryptoNews + Decrypt) → script TikTok FR (Claude Haiku, avec hashtags) → note de viralité → voix ElevenLabs alternée → **email de suivi** (script + audio MP3). Email d'alerte si ça plante.

100 % gratuit (infra GitHub Actions), aucun serveur à maintenir, rien qui expire.

## Mise en route (à faire une seule fois)

1. **Secrets** : dans le repo → `Settings` → `Secrets and variables` → `Actions` → `New repository secret`. Ajoute :
   | Nom | Valeur |
   |-----|--------|
   | `ANTHROPIC_API_KEY` | ta clé Anthropic (régénérée de préférence) |
   | `ELEVENLABS_API_KEY` | ta clé ElevenLabs (régénérée de préférence) |
   | `GMAIL_USER` | `moncompte.scenes@gmail.com` |
   | `GMAIL_APP_PASSWORD` | un **mot de passe d'application** Gmail (voir ci-dessous) |
   | `MAIL_TO` *(optionnel)* | adresse de réception (défaut = `GMAIL_USER`) |

2. **Mot de passe d'application Gmail** (le mot de passe normal ne marche pas en SMTP) :
   Compte Google → Sécurité → Validation en 2 étapes (activée) → **Mots de passe des applications** → en créer un « Mail », copier les 16 caractères → le coller dans `GMAIL_APP_PASSWORD`.

3. **Tester** : onglet `Actions` → « Daily TikTok Crypto Script » → **Run workflow**. Tu dois recevoir l'email en ~1 min.

Le cron tourne ensuite tout seul chaque jour. (07:00 UTC = 9h Paris l'été, 8h l'hiver — ajustable dans `.github/workflows/daily-tiktok.yml`.)

## Fichiers
- `daily_tiktok.py` — le script.
- `.github/workflows/daily-tiktok.yml` — le planificateur (cron + bouton manuel).
- `requirements.txt` — dépendances.
