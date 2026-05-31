#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Daily TikTok Crypto — bot gratuit & perenne (GitHub Actions).

Chaque jour :
  RSS crypto (CoinDesk + CryptoNews + Decrypt)
  -> choix de l'article le plus "viral"
  -> script TikTok FR (Claude Haiku, avec hashtags)
  -> (optionnel) voix ElevenLabs alternee, commitee dans le repo
  -> LIVRAISON : ouverture d'une Issue GitHub avec le script
     + @mention du proprietaire  ==>  GitHub t'envoie un EMAIL automatiquement.

Aucun mot de passe Gmail requis : on utilise le GITHUB_TOKEN fourni par Actions.

Secrets requis :
  ANTHROPIC_API_KEY   (obligatoire)
Secrets optionnels :
  ELEVENLABS_API_KEY  (si present -> ajoute l'audio MP3)
Variables fournies AUTOMATIQUEMENT par GitHub Actions :
  GITHUB_TOKEN, GITHUB_REPOSITORY
"""

import base64
import datetime as dt
import os
import re
import sys
import traceback

import feedparser
import requests

# ---------------------------------------------------------------- config
ANTHROPIC_API_KEY = os.environ.get("ANTHROPIC_API_KEY", "").strip()
ELEVENLABS_API_KEY = os.environ.get("ELEVENLABS_API_KEY", "").strip()
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "").strip()
GITHUB_REPOSITORY = os.environ.get("GITHUB_REPOSITORY", "").strip()  # "owner/repo"

CLAUDE_MODEL = "claude-haiku-4-5-20251001"

RSS_FEEDS = [
    "https://www.coindesk.com/arc/outboundfeeds/rss/",
    "https://cryptonews.com/news/feed/",
    "https://decrypt.co/feed",
]

HASHTAGS = "#crypto #bitcoin #btc #cryptofr #actualitécrypto #blockchain"

# Voix ElevenLabs alternees jour pair / impair
VOICE_EVEN = "JBFqnCBsd6RMkjVDRZzb"
VOICE_ODD = "EXAVITQu4vr4xnSDxMaL"

SHOCK_WORDS = [
    "krach", "explose", "record", "chute", "alerte", "arnaque", "piratage",
    "milliard", "million", "interdit", "scandale", "boom", "flambee",
    "effondrement", "historique", "urgent",
]


# ---------------------------------------------------------------- helpers
def viral_score(text: str) -> int:
    t = (text or "").lower()
    score = 0
    if re.search(r"\d", t):
        score += 3
    if any(w in t for w in SHOCK_WORDS):
        score += 2
    if len(t.split()) < 80:
        score += 2
    if re.search(r"[\U0001F300-\U0001FAFF]", text or ""):
        score += 1
    return score


def get_articles():
    items = []
    for url in RSS_FEEDS:
        try:
            feed = feedparser.parse(url)
            for e in feed.entries[:10]:
                items.append(
                    {
                        "title": getattr(e, "title", "").strip(),
                        "summary": re.sub(r"<[^>]+>", "", getattr(e, "summary", ""))[:400],
                        "link": getattr(e, "link", ""),
                    }
                )
        except Exception as exc:  # une source HS ne doit pas tout casser
            print(f"[warn] feed KO {url}: {exc}", file=sys.stderr)
    return items


def pick_article(items):
    if not items:
        raise RuntimeError("Aucun article RSS recupere (les 3 sources ont echoue).")
    items.sort(key=lambda a: viral_score(a["title"]), reverse=True)
    return items[0]


def generate_script(article) -> str:
    prompt = (
        "Tu es un createur TikTok crypto francophone. A partir de cette actu, "
        "ecris un script TikTok de 30 secondes en FRANCAIS, percutant et viral.\n"
        "Structure : un HOOK choc (1 phrase) + 2 faits cles + un CTA (abonne-toi).\n"
        "Style parle, phrases courtes, max ~80 mots. Termine par ces hashtags : "
        f"{HASHTAGS}\n\n"
        f"TITRE : {article['title']}\n"
        f"RESUME : {article['summary']}\n"
        f"SOURCE : {article['link']}\n"
    )
    r = requests.post(
        "https://api.anthropic.com/v1/messages",
        headers={
            "x-api-key": ANTHROPIC_API_KEY,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
        json={
            "model": CLAUDE_MODEL,
            "max_tokens": 600,
            "messages": [{"role": "user", "content": prompt}],
        },
        timeout=60,
    )
    r.raise_for_status()
    data = r.json()
    return data["content"][0]["text"].strip()


def make_audio(script: str):
    """Retourne (filename, bytes) ou None si pas de cle ElevenLabs / echec."""
    if not ELEVENLABS_API_KEY:
        return None
    try:
        voice = VOICE_EVEN if dt.date.today().toordinal() % 2 == 0 else VOICE_ODD
        r = requests.post(
            f"https://api.elevenlabs.io/v1/text-to-speech/{voice}",
            headers={
                "xi-api-key": ELEVENLABS_API_KEY,
                "content-type": "application/json",
                "accept": "audio/mpeg",
            },
            json={"text": script, "model_id": "eleven_multilingual_v2"},
            timeout=120,
        )
        r.raise_for_status()
        fname = f"audio/{dt.date.today().isoformat()}.mp3"
        return fname, r.content
    except Exception as exc:
        print(f"[warn] audio KO: {exc}", file=sys.stderr)
        return None


def gh_commit_file(path: str, content_bytes: bytes, message: str):
    """Commit un fichier binaire dans le repo (pour l'audio). Best-effort."""
    url = f"https://api.github.com/repos/{GITHUB_REPOSITORY}/contents/{path}"
    payload = {
        "message": message,
        "content": base64.b64encode(content_bytes).decode("ascii"),
    }
    r = requests.put(url, headers=_gh_headers(), json=payload, timeout=60)
    r.raise_for_status()
    return r.json()["content"]["download_url"]


def gh_create_issue(title: str, body: str):
    url = f"https://api.github.com/repos/{GITHUB_REPOSITORY}/issues"
    r = requests.post(url, headers=_gh_headers(), json={"title": title, "body": body}, timeout=60)
    r.raise_for_status()
    return r.json()["html_url"]


def _gh_headers():
    return {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }


def owner_handle() -> str:
    return GITHUB_REPOSITORY.split("/")[0] if "/" in GITHUB_REPOSITORY else ""


# ---------------------------------------------------------------- main
def main():
    if not ANTHROPIC_API_KEY:
        raise RuntimeError("Secret ANTHROPIC_API_KEY manquant.")
    if not (GITHUB_TOKEN and GITHUB_REPOSITORY):
        raise RuntimeError("GITHUB_TOKEN / GITHUB_REPOSITORY absents (lancer via GitHub Actions).")

    today = dt.date.today().isoformat()
    article = pick_article(get_articles())
    script = generate_script(article)

    audio = make_audio(script)
    audio_line = ""
    if audio:
        try:
            fname, content = audio
            dl = gh_commit_file(fname, content, f"audio {today}")
            audio_line = f"\n\n**Audio du jour :** {dl}"
        except Exception as exc:
            print(f"[warn] commit audio KO: {exc}", file=sys.stderr)

    mention = owner_handle()
    body = (
        (f"@{mention}\n\n" if mention else "")
        + f"**Script TikTok crypto - {today}**\n\n"
        + "```\n" + script + "\n```\n\n"
        + f"Source : {article['title']}\n{article['link']}"
        + audio_line
        + "\n\n_Genere automatiquement par le bot (GitHub Actions)._"
    )
    issue_url = gh_create_issue(f"TikTok crypto - {today}", body)
    print(f"Issue creee : {issue_url}")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        tb = traceback.format_exc()
        print(tb, file=sys.stderr)
        # Tente de remonter l'erreur par email (via une issue) si possible
        try:
            if GITHUB_TOKEN and GITHUB_REPOSITORY:
                m = owner_handle()
                gh_create_issue(
                    f"[ERREUR] Bot crypto - {dt.date.today().isoformat()}",
                    (f"@{m}\n\n" if m else "") + "Le bot a echoue :\n\n```\n" + tb + "\n```",
                )
        except Exception as exc:
            print(f"[warn] impossible de notifier l'erreur: {exc}", file=sys.stderr)
        sys.exit(1)
