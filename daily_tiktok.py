#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Daily TikTok Crypto — script + audio par email (remplace le Pipeline 1 n8n).
Gratuit et pérenne : tourne via GitHub Actions (cron quotidien).

Étapes :
  1. Récupère les articles crypto récents de 3 flux RSS (CoinDesk, CryptoNews, Decrypt)
  2. Génère un script TikTok FR (Claude Haiku) avec hashtags
  3. Note la "viralité" du script (garde le meilleur, vise un score >= 6)
  4. Voix ElevenLabs alternée selon le jour (pair / impair)
  5. Envoie le script + l'audio MP3 par email (suivi de progression)
  6. En cas d'erreur : email d'alerte

Tous les secrets viennent des variables d'environnement (GitHub Secrets) —
aucune clé n'est écrite dans le code.
"""

import os
import sys
import base64
import datetime as dt
import smtplib
import re
from email.message import EmailMessage

import requests
import feedparser

# ---------------------------------------------------------------- config
ANTHROPIC_API_KEY = os.environ.get("ANTHROPIC_API_KEY", "")
ELEVENLABS_API_KEY = os.environ.get("ELEVENLABS_API_KEY", "")
GMAIL_USER = os.environ.get("GMAIL_USER", "")          # ex: moncompte.scenes@gmail.com
GMAIL_APP_PASSWORD = os.environ.get("GMAIL_APP_PASSWORD", "")
MAIL_TO = os.environ.get("MAIL_TO", GMAIL_USER)        # par défaut, s'envoie à soi-même

CLAUDE_MODEL = "claude-haiku-4-5-20251001"

RSS_FEEDS = [
    "https://www.coindesk.com/arc/outboundfeeds/rss/",
    "https://cryptonews.com/news/feed/",
    "https://decrypt.co/feed",
]

# Amélioration #4 : voix alternée selon le jour
VOICE_EVEN = "JBFqnCBsd6RMkjVDRZzb"   # jour pair
VOICE_ODD = "EXAVITQu4vr4xnSDxMaL"    # jour impair

SHOCK_WORDS = ["officiel", "record", "crash", "pump", "sec", "etf", "explose",
               "alerte", "historique", "interdit", "approuvé", "milliard"]


# ---------------------------------------------------------------- helpers
def log(msg):
    print(f"[{dt.datetime.now().isoformat(timespec='seconds')}] {msg}", flush=True)


def fetch_articles():
    """Récupère les articles récents des 3 flux, triés du plus récent au plus ancien."""
    items = []
    for url in RSS_FEEDS:
        try:
            feed = feedparser.parse(url)
            for e in feed.entries[:10]:
                title = (e.get("title") or "").strip()
                summary = re.sub("<[^>]+>", "", e.get("summary", "") or "").strip()
                published = e.get("published_parsed") or e.get("updated_parsed")
                ts = dt.datetime(*published[:6]) if published else dt.datetime.min
                if title:
                    items.append({"title": title, "summary": summary[:400],
                                  "link": e.get("link", ""), "source": url, "ts": ts})
            log(f"RSS OK ({len(feed.entries)} entrées) : {url}")
        except Exception as ex:
            log(f"RSS ERREUR {url} : {ex}")
    items.sort(key=lambda x: x["ts"], reverse=True)
    return items


def generate_script(title, summary):
    """Amélioration #3 : hashtags inclus dans le prompt."""
    prompt = (
        "Tu es un créateur TikTok viral spécialisé crypto. "
        "Crée un script de 30 secondes EN FRANÇAIS pour ce sujet : "
        f"\"{title}\". Contexte : {summary}\n\n"
        "Format STRICT :\n"
        "HOOK (5 s, choc) + 2 FAITS CLÉS (20 s) + CTA (5 s).\n"
        "Style viral, percutant, avec quelques emojis. Moins de 80 mots.\n"
        "Termine par une ligne HASHTAGS : "
        "#crypto #bitcoin #btc #cryptofr #actualitécrypto #blockchain"
    )
    r = requests.post(
        "https://api.anthropic.com/v1/messages",
        headers={
            "anthropic-version": "2023-06-01",
            "x-api-key": ANTHROPIC_API_KEY,
            "content-type": "application/json",
        },
        json={
            "model": CLAUDE_MODEL,
            "max_tokens": 300,
            "messages": [{"role": "user", "content": prompt}],
        },
        timeout=60,
    )
    r.raise_for_status()
    data = r.json()
    return "".join(block.get("text", "") for block in data.get("content", [])).strip()


def viral_score(script):
    """Amélioration #2 : note 1-10 du potentiel viral."""
    s = script.lower()
    score = 0
    if re.search(r"\d", script):
        score += 3                                   # contient un chiffre / stat
    if any(w in s for w in SHOCK_WORDS):
        score += 2                                   # mot choc
    word_count = len(re.findall(r"\w+", script))
    if word_count < 80:
        score += 2                                   # court = punchy
    if re.search(r"[\U0001F300-\U0001FAFF☀-➿]", script):
        score += 1                                   # emoji
    return score


def pick_best_script(articles, min_score=6, max_tries=4):
    """Génère des scripts jusqu'à atteindre un bon score viral (sinon garde le meilleur)."""
    best = None
    for art in articles[:max_tries]:
        try:
            script = generate_script(art["title"], art["summary"])
        except Exception as ex:
            log(f"Claude ERREUR sur '{art['title']}' : {ex}")
            continue
        sc = viral_score(script)
        log(f"Script généré (score {sc}/10) ← {art['title']}")
        if best is None or sc > best["score"]:
            best = {"article": art, "script": script, "score": sc}
        if sc >= min_score:
            break
    return best


def tts(script, voice_id):
    r = requests.post(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}",
        headers={"xi-api-key": ELEVENLABS_API_KEY, "content-type": "application/json"},
        json={"text": script, "model_id": "eleven_multilingual_v2"},
        timeout=120,
    )
    r.raise_for_status()
    return r.content  # MP3 bytes


def send_email(subject, body, mp3_bytes=None, mp3_name="tiktok.mp3"):
    msg = EmailMessage()
    msg["From"] = GMAIL_USER
    msg["To"] = MAIL_TO
    msg["Subject"] = subject
    msg.set_content(body)
    if mp3_bytes:
        msg.add_attachment(mp3_bytes, maintype="audio", subtype="mpeg", filename=mp3_name)
    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
        smtp.login(GMAIL_USER, GMAIL_APP_PASSWORD)
        smtp.send_message(msg)
    log(f"Email envoyé → {MAIL_TO}")


# ---------------------------------------------------------------- main
def main():
    missing = [k for k in ("ANTHROPIC_API_KEY", "ELEVENLABS_API_KEY",
                           "GMAIL_USER", "GMAIL_APP_PASSWORD") if not os.environ.get(k)]
    if missing:
        log(f"Secrets manquants : {missing}")
        sys.exit(1)

    articles = fetch_articles()
    if not articles:
        raise RuntimeError("Aucun article récupéré depuis les flux RSS.")

    best = pick_best_script(articles)
    if not best:
        raise RuntimeError("Impossible de générer un script.")

    day_even = dt.date.today().day % 2 == 0
    voice_id = VOICE_EVEN if day_even else VOICE_ODD
    mp3 = tts(best["script"], voice_id)

    art = best["article"]
    today = dt.date.today().strftime("%d/%m/%Y")
    body = (
        f"📈 SUIVI TIKTOK CRYPTO — {today}\n"
        f"{'='*40}\n\n"
        f"Score viral : {best['score']}/10\n"
        f"Source : {art['title']}\n"
        f"Lien : {art['link']}\n"
        f"Voix : {'paire' if day_even else 'impaire'} ({voice_id})\n\n"
        f"--- SCRIPT ---\n{best['script']}\n\n"
        f"(Audio MP3 en pièce jointe.)"
    )
    send_email(f"🎬 Script TikTok — {art['title'][:60]}", body, mp3, f"tiktok_{today.replace('/','-')}.mp3")
    log("Terminé avec succès.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # Amélioration #5 : alerte par email si ça plante
        log(f"ÉCHEC : {e}")
        try:
            if GMAIL_USER and GMAIL_APP_PASSWORD:
                send_email("🚨 ALERTE — Le bot TikTok crypto a planté",
                           f"Le workflow quotidien a échoué :\n\n{e}\n\n"
                           f"Vérifie les logs GitHub Actions.")
        except Exception as e2:
            log(f"Échec de l'email d'alerte : {e2}")
        sys.exit(1)
