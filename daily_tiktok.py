#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Daily TikTok Crypto — bot 100% gratuit & perenne (GitHub Actions).

Chaque jour :
  RSS crypto (CoinDesk + CryptoNews + Decrypt)
  -> article le plus "viral"
  -> script TikTok FR (GitHub Models, gratuit via le GITHUB_TOKEN)
  -> VOIX OFF FR gratuite (edge-tts) + VISUEL (Pillow) + VIDEO verticale (ffmpeg)
  -> video commitee dans le repo (dossier video/)
  -> Issue GitHub avec le script (= legende a copier) + lien de la video
     + @mention du proprietaire  ==>  GitHub t'envoie un EMAIL.

Tu telecharges la video et tu la postes toi-meme sur TikTok (10 s) :
  -> 0 EUR, rien qui expire, et AUCUN risque de ban (c'est toi qui postes).

AUCUNE cle API a fournir : tout tourne avec le GITHUB_TOKEN d'Actions.
(Workflow : permissions models:read, issues:write, contents:write
 + apt: ffmpeg, fonts-dejavu-core ; pip: edge-tts, Pillow)
"""

import asyncio
import base64
import datetime as dt
import os
import re
import subprocess
import sys
import traceback

import feedparser
import requests

# ---------------------------------------------------------------- config
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "").strip()
GITHUB_REPOSITORY = os.environ.get("GITHUB_REPOSITORY", "").strip()  # "owner/repo"

GH_MODELS_URL = "https://models.github.ai/inference/chat/completions"
GH_MODEL = "openai/gpt-4.1"
GH_API_VERSION = "2026-03-10"

RSS_FEEDS = [
    "https://www.coindesk.com/arc/outboundfeeds/rss/",
    "https://cryptonews.com/news/feed/",
    "https://decrypt.co/feed",
]

HASHTAGS = "#crypto #bitcoin #btc #cryptofr #actualitécrypto #blockchain"
HANDLE = "@legendarymoments000"

# Voix edge-tts (gratuites) alternees jour pair / impair
VOICE_EVEN = "fr-FR-DeniseNeural"
VOICE_ODD = "fr-FR-HenriNeural"

FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

SHOCK_WORDS = [
    "krach", "explose", "record", "chute", "alerte", "arnaque", "piratage",
    "milliard", "million", "interdit", "scandale", "boom", "flambee",
    "effondrement", "historique", "urgent",
]


# ---------------------------------------------------------------- helpers texte
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
        except Exception as exc:
            print(f"[warn] feed KO {url}: {exc}", file=sys.stderr)
    return items


def pick_article(items):
    if not items:
        raise RuntimeError("Aucun article RSS recupere (les 3 sources ont echoue).")
    items.sort(key=lambda a: viral_score(a["title"]), reverse=True)
    return items[0]


def generate_script(article) -> str:
    prompt = (
        "A partir de cette actu crypto, ecris un script TikTok de 30 secondes en "
        "FRANCAIS, percutant et viral.\n"
        "Structure : un HOOK choc (1 phrase) + 2 faits cles + un CTA (abonne-toi).\n"
        "Style parle, phrases courtes, max ~80 mots. Pas d'emojis. "
        "Termine par une ligne avec ces hashtags : "
        f"{HASHTAGS}\n\n"
        f"TITRE : {article['title']}\n"
        f"RESUME : {article['summary']}\n"
        f"SOURCE : {article['link']}\n"
    )
    r = requests.post(
        GH_MODELS_URL,
        headers={
            "Authorization": f"Bearer {GITHUB_TOKEN}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-GitHub-Api-Version": GH_API_VERSION,
        },
        json={
            "model": GH_MODEL,
            "messages": [
                {"role": "system", "content": "Tu es un createur TikTok crypto francophone."},
                {"role": "user", "content": prompt},
            ],
            "max_tokens": 600,
            "temperature": 0.8,
        },
        timeout=90,
    )
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()


def split_script(script: str):
    """Retourne (texte_a_dire_et_afficher, legende_complete)."""
    lines = [ln.strip() for ln in script.splitlines() if ln.strip()]
    spoken = [ln for ln in lines if not ln.lstrip().startswith("#")]
    spoken_text = "\n".join(spoken).strip()
    return spoken_text, script.strip()


# ---------------------------------------------------------------- voix (edge-tts)
def make_voice(text: str, out_mp3: str) -> bool:
    try:
        import edge_tts

        voice = VOICE_EVEN if dt.date.today().toordinal() % 2 == 0 else VOICE_ODD

        async def _run():
            await edge_tts.Communicate(text, voice).save(out_mp3)

        asyncio.run(_run())
        return os.path.getsize(out_mp3) > 1000
    except Exception as exc:
        print(f"[warn] voix KO: {exc}", file=sys.stderr)
        return False


# ---------------------------------------------------------------- visuel (Pillow)
def _font(size: int):
    from PIL import ImageFont

    try:
        return ImageFont.truetype(FONT_BOLD, size)
    except Exception:
        return ImageFont.load_default()


def _wrap(draw, text, font, max_w):
    out = []
    for para in text.split("\n"):
        words = para.split()
        cur = ""
        for w in words:
            t = (cur + " " + w).strip()
            if draw.textlength(t, font=font) <= max_w or not cur:
                cur = t
            else:
                out.append(cur)
                cur = w
        out.append(cur)
    return out


def make_background(spoken_text: str, out_png: str):
    from PIL import Image, ImageDraw

    W, H = 1080, 1920
    top, bot = (15, 32, 39), (32, 58, 86)
    grad = Image.new("RGB", (1, H))
    for y in range(H):
        f = y / H
        grad.putpixel(
            (0, y),
            (
                int(top[0] + (bot[0] - top[0]) * f),
                int(top[1] + (bot[1] - top[1]) * f),
                int(top[2] + (bot[2] - top[2]) * f),
            ),
        )
    img = grad.resize((W, H))
    d = ImageDraw.Draw(img)
    margin = 90
    max_w = W - 2 * margin

    parts = [p for p in spoken_text.split("\n") if p.strip()]
    hook = parts[0] if parts else spoken_text
    body = "\n".join(parts[1:]) if len(parts) > 1 else ""

    f_hook = _font(66)
    f_body = _font(46)
    f_foot = _font(40)

    y = 180
    for line in _wrap(d, hook, f_hook, max_w):
        d.text((margin, y), line, font=f_hook, fill=(255, 255, 255))
        y += 78
    y += 40
    for line in _wrap(d, body, f_body, max_w):
        d.text((margin, y), line, font=f_body, fill=(220, 230, 235))
        y += 60

    d.text((margin, H - 130), HANDLE, font=f_foot, fill=(120, 200, 255))
    img.save(out_png)


def build_video(spoken_text: str, out_mp4: str):
    """Construit la video. Retourne le chemin du mp4, ou None si echec voix."""
    mp3 = "voice.mp3"
    if not make_voice(spoken_text, mp3):
        return None
    bg = "bg.png"
    make_background(spoken_text, bg)
    subprocess.run(
        [
            "ffmpeg", "-y",
            "-loop", "1", "-i", bg,
            "-i", mp3,
            "-c:v", "libx264", "-tune", "stillimage", "-r", "30",
            "-c:a", "aac", "-b:a", "192k",
            "-pix_fmt", "yuv420p",
            "-vf", "scale=1080:1920",
            "-shortest",
            out_mp4,
        ],
        check=True,
    )
    return out_mp4


# ---------------------------------------------------------------- GitHub API
def _gh_headers():
    return {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }


def gh_commit_file(path: str, content_bytes: bytes, message: str):
    url = f"https://api.github.com/repos/{GITHUB_REPOSITORY}/contents/{path}"
    payload = {"message": message, "content": base64.b64encode(content_bytes).decode("ascii")}
    r = requests.put(url, headers=_gh_headers(), json=payload, timeout=120)
    r.raise_for_status()
    j = r.json()
    return j["content"]["html_url"], j["content"]["download_url"]


def gh_create_issue(title: str, body: str):
    url = f"https://api.github.com/repos/{GITHUB_REPOSITORY}/issues"
    r = requests.post(url, headers=_gh_headers(), json={"title": title, "body": body}, timeout=60)
    r.raise_for_status()
    return r.json()["html_url"]


def owner_handle() -> str:
    return GITHUB_REPOSITORY.split("/")[0] if "/" in GITHUB_REPOSITORY else ""


# ---------------------------------------------------------------- main
def main():
    if not (GITHUB_TOKEN and GITHUB_REPOSITORY):
        raise RuntimeError("GITHUB_TOKEN / GITHUB_REPOSITORY absents (lancer via GitHub Actions).")

    today = dt.date.today().isoformat()
    article = pick_article(get_articles())
    script = generate_script(article)
    spoken, caption = split_script(script)

    video_block = "_Video non generee cette fois (voix indisponible) — utilise le script ci-dessus._"
    try:
        mp4 = build_video(spoken, f"{today}.mp4")
        if mp4:
            with open(mp4, "rb") as f:
                page, _dl = gh_commit_file(f"video/{today}.mp4", f.read(), f"video {today}")
            # Lien RAW stable (repo public) — pas de jeton qui expire
            raw = f"https://raw.githubusercontent.com/{GITHUB_REPOSITORY}/main/video/{today}.mp4"
            video_block = f"🎬 **Vidéo prête à poster :** [Télécharger la vidéo]({raw})\n\n_(aperçu dans le navigateur : {page})_"
    except Exception as exc:
        print(f"[warn] video KO: {exc}", file=sys.stderr)
        video_block = f"_Video KO ({exc}). Utilise le script ci-dessus._"

    mention = owner_handle()
    body = (
        (f"@{mention}\n\n" if mention else "")
        + f"**TikTok crypto — {today}**\n\n"
        + video_block
        + "\n\n---\n\n**Légende / script à copier :**\n\n"
        + "```\n" + caption + "\n```\n\n"
        + f"📰 Source : {article['title']}\n{article['link']}\n\n"
        + "_Genere automatiquement (GitHub Actions + GitHub Models + edge-tts)._"
    )
    issue_url = gh_create_issue(f"TikTok crypto - {today}", body)
    print(f"Issue creee : {issue_url}")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        tb = traceback.format_exc()
        print(tb, file=sys.stderr)
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
