#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Daily TikTok Crypto — bot 100% gratuit & perenne (GitHub Actions).

Chaque jour :
  RSS crypto (CoinDesk + CryptoNews + Decrypt)
  -> article le plus "viral"
  -> script TikTok FR (GitHub Models, gratuit via le GITHUB_TOKEN)
  -> VOIX OFF FR gratuite (edge-tts) AVEC timings mot-a-mot
  -> VIDEO verticale DYNAMIQUE (ffmpeg) : fond degrade anime (gradients)
     + sous-titres animes synchronises a la voix (style TikTok, libass)
  -> video commitee dans video/<date>.mp4
  -> Issue GitHub : lien de telechargement (RAW stable) + legende a copier
     + @mention du proprietaire  ==>  EMAIL automatique.

Tu telecharges la video et tu la postes toi-meme (10 s) : 0 EUR, pas de ban.

AUCUNE cle API : tout tourne avec le GITHUB_TOKEN d'Actions.
(Workflow : permissions models:read, issues:write, contents:write
 + apt: ffmpeg fonts-dejavu-core ; pip: edge-tts)
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
HANDLE = "@don.sodialia"
TOP_LABEL = "ACTU CRYPTO"

# Voix edge-tts (gratuites) alternees jour pair / impair
VOICE_EVEN = "fr-FR-DeniseNeural"
VOICE_ODD = "fr-FR-HenriNeural"

SHOCK_WORDS = [
    "krach", "explose", "record", "chute", "alerte", "arnaque", "piratage",
    "milliard", "million", "interdit", "scandale", "boom", "flambee",
    "effondrement", "historique", "urgent",
]


# ---------------------------------------------------------------- texte
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
    """Retourne (texte_a_dire, legende_complete). Le texte dit exclut la ligne de hashtags."""
    lines = [ln.strip() for ln in script.splitlines() if ln.strip()]
    spoken = [ln for ln in lines if not ln.lstrip().startswith("#")]
    return " ".join(spoken).strip(), script.strip()


# ---------------------------------------------------------------- voix + timings
def synthesize(text: str, mp3_path: str):
    """edge-tts : ecrit le mp3 et renvoie [(start_s, end_s, mot), ...]."""
    import edge_tts

    voice = VOICE_EVEN if dt.date.today().toordinal() % 2 == 0 else VOICE_ODD
    words = []

    async def _run():
        comm = edge_tts.Communicate(text, voice)
        with open(mp3_path, "wb") as f:
            async for ch in comm.stream():
                t = ch.get("type")
                if t == "audio" and ch.get("data"):
                    f.write(ch["data"])
                elif t in ("WordBoundary", "SentenceBoundary"):
                    off = float(ch.get("offset", 0)) / 1e7
                    dur = float(ch.get("duration", 0)) / 1e7
                    w = (ch.get("text") or "").strip()
                    if w:
                        words.append((off, off + dur, w))

    asyncio.run(_run())
    return words


def audio_duration(path: str) -> float:
    try:
        out = subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "default=noprint_wrappers=1:nokey=1", path],
            capture_output=True, text=True, check=True,
        )
        return float(out.stdout.strip())
    except Exception:
        return 0.0


# ---------------------------------------------------------------- sous-titres ASS
def _ass_ts(t: float) -> str:
    if t < 0:
        t = 0.0
    h = int(t // 3600)
    m = int((t % 3600) // 60)
    s = t % 60
    return f"{h:d}:{m:02d}:{s:05.2f}"


def _ass_safe(txt: str) -> str:
    return txt.replace("{", "(").replace("}", ")").replace("\\", "/").replace("\n", " ").strip()


def chunks_from_segments(segs, total_dur, spoken):
    """Decoupe chaque segment (mot OU phrase) en blocs de <=3 mots, repartis
    dans la fenetre temporelle du segment. Fallback : split regulier global."""
    chunks = []
    if segs:
        for s, e, txt in segs:
            toks = txt.split()
            groups = [toks[i:i + 3] for i in range(0, len(toks), 3)] or [toks]
            span = max(0.01, (e - s) / len(groups))
            for idx, g in enumerate(groups):
                chunks.append([s + idx * span, s + (idx + 1) * span, " ".join(g)])
        if chunks:
            chunks[-1][1] = max(chunks[-1][1], total_dur - 0.05)
    else:
        toks = spoken.split()
        groups = [toks[i:i + 3] for i in range(0, len(toks), 3)] or [toks]
        dur = (total_dur or len(groups)) / max(1, len(groups))
        for idx, g in enumerate(groups):
            chunks.append([idx * dur, (idx + 1) * dur, " ".join(g)])
    return chunks


def build_ass(words, total_dur, spoken, ass_path):
    end_all = _ass_ts(total_dur)
    header = (
        "[Script Info]\n"
        "ScriptType: v4.00+\nPlayResX: 1080\nPlayResY: 1920\nWrapStyle: 0\n"
        "ScaledBorderAndShadow: yes\n\n"
        "[V4+ Styles]\n"
        "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, "
        "BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, "
        "BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\n"
        "Style: Cap,DejaVu Sans,96,&H00FFFFFF,&H000F6FFF,&H00101010,&H64000000,-1,0,0,0,"
        "100,100,0,0,1,7,3,5,90,90,0,1\n"
        "Style: Lab,DejaVu Sans,52,&H00FFE6B0,&H000000FF,&H00101010,&H64000000,-1,0,0,0,"
        "100,100,2,0,1,5,2,8,60,60,120,1\n"
        "Style: Tag,DejaVu Sans,46,&H005A9CFF,&H000000FF,&H00101010,&H64000000,-1,0,0,0,"
        "100,100,0,0,1,4,2,2,60,60,90,1\n\n"
        "[Events]\n"
        "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n"
    )
    pop = (r"{\fad(60,40)\fscx72\fscy72\t(0,130,\fscx112\fscy112)"
           r"\t(130,230,\fscx100\fscy100)}")
    lines = [
        f"Dialogue: 0,0:00:00.00,{end_all},Lab,,0,0,0,,{TOP_LABEL}",
        f"Dialogue: 0,0:00:00.00,{end_all},Tag,,0,0,0,,{HANDLE}",
    ]
    for start, end, txt in chunks_from_segments(words, total_dur, spoken):
        lines.append(
            f"Dialogue: 1,{_ass_ts(start)},{_ass_ts(end)},Cap,,0,0,0,,{pop}{_ass_safe(txt)}"
        )
    with open(ass_path, "w", encoding="utf-8") as f:
        f.write(header + "\n".join(lines) + "\n")


# ---------------------------------------------------------------- visuel (fond anime)
def _font(size: int):
    from PIL import ImageFont
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except Exception:
        return ImageFont.load_default()


def make_tokens(path: str):
    """Pattern de symboles crypto (transparent), hauteur double => defilement sans couture."""
    import random
    from PIL import Image, ImageDraw

    W, Hb = 1080, 1920
    block = Image.new("RGBA", (W, Hb), (0, 0, 0, 0))
    d = ImageDraw.Draw(block)
    font = _font(60)
    tokens = ["BTC", "ETH", "SOL", "XRP", "BNB", "$", "+5%", "-3%", "$68K",
              "1 BTC", "ATH", "HODL", "▲", "▼"]
    palette = [(90, 200, 255, 255), (120, 230, 170, 255),
               (255, 180, 90, 255), (190, 205, 235, 255)]
    random.seed(7)
    cols, rows = 4, 6
    cw, chh = W / cols, Hb / rows
    for r in range(rows):
        for c in range(cols):
            x = int(c * cw + random.uniform(8, 40))
            y = int(r * chh + random.uniform(8, 40))
            d.text((x, y), random.choice(tokens), font=font, fill=random.choice(palette))
    full = Image.new("RGBA", (W, Hb * 2), (0, 0, 0, 0))
    full.paste(block, (0, 0))
    full.paste(block, (0, Hb))
    full.save(path)


def fetch_markets():
    """Top 100 cryptos (CoinGecko, gratuit) avec variation 24h + courbe 7j."""
    url = (
        "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd"
        "&order=market_cap_desc&per_page=100&page=1&sparkline=true"
        "&price_change_percentage=24h"
    )
    r = requests.get(url, headers={"accept": "application/json"}, timeout=30)
    r.raise_for_status()
    out = []
    for x in r.json():
        sp = (x.get("sparkline_in_7d") or {}).get("price") or []
        sp = [p for p in sp if isinstance(p, (int, float))]
        pc = x.get("price_change_percentage_24h")
        if pc is None or len(sp) < 24:
            continue
        sym = re.sub(r"[^A-Z0-9$.+-]", "", (x.get("symbol") or "").upper())[:8] or "COIN"
        out.append({"sym": sym, "pc": float(pc), "sp": sp})
    return out


def _draw_spark(d, box, prices, color):
    x0, y0, x1, y1 = box
    lo, hi = min(prices), max(prices)
    rng = (hi - lo) or 1.0
    n = len(prices)
    pts = [(x0 + (x1 - x0) * i / (n - 1), y1 - (y1 - y0) * ((p - lo) / rng))
           for i, p in enumerate(prices)]
    d.line(pts, fill=color + (70,), width=16, joint="curve")
    d.line(pts, fill=color + (255,), width=6, joint="curve")


def make_chart(path: str, n: int = 4):
    """Graphe REEL : top hausses (vert) + top baisses (rouge). Retourne la largeur, ou None."""
    data = fetch_markets()
    if len(data) < 4:
        return None
    data.sort(key=lambda z: z["pc"])
    losers = data[:n]
    gainers = list(reversed(data[-n:]))
    from PIL import Image, ImageDraw

    cw, pad, H = 660, 50, 1920
    cols = max(len(gainers), len(losers))
    W2 = pad * 2 + cols * cw
    img = Image.new("RGBA", (W2, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    flbl, fpct = _font(48), _font(58)
    green, red = (70, 225, 140), (255, 95, 95)

    def band(coins, top):
        ch = 380
        for i, c in enumerate(coins):
            col = green if c["pc"] >= 0 else red
            x0 = pad + i * cw + 40
            x1 = pad + i * cw + cw - 40
            _draw_spark(d, (x0, top, x1, top + ch), c["sp"], col)
            d.text((x0, top - 66), c["sym"], font=flbl, fill=(235, 240, 245, 255))
            sign = "+" if c["pc"] >= 0 else ""
            d.text((x0, top + ch + 14), f"{sign}{c['pc']:.1f}%", font=fpct, fill=col + (255,))

    band(gainers, 360)    # bande du haut : ca monte (vert)
    band(losers, 1170)    # bande du bas : ca chute (rouge)
    img.save(path)
    return W2


# ---------------------------------------------------------------- video
def build_video(spoken: str, out_mp4: str):
    """Video dynamique. Retourne le chemin du mp4, ou None si la voix echoue."""
    mp3 = "voice.mp3"
    try:
        words = synthesize(spoken, mp3)
    except Exception as exc:
        print(f"[warn] voix KO: {exc}", file=sys.stderr)
        return None
    if not (os.path.exists(mp3) and os.path.getsize(mp3) > 1000):
        return None

    dur = audio_duration(mp3) or (len(spoken.split()) / 2.7)
    ass = "cap.ass"
    build_ass(words, dur, spoken, ass)

    grad = (
        f"gradients=s=1080x1920:c0=0x0F2027:c1=0x16263F:c2=0x213F5E:"
        f"d={dur:.2f}:speed=0.012:r=30"
    )

    # Fond = vrai graphique des cryptos qui montent (vert) / chutent (rouge),
    # qui defile horizontalement. Repli sur les symboles si la data echoue.
    chart_w = None
    try:
        chart_w = make_chart("chart.png")
    except Exception as exc:
        print(f"[warn] chart KO: {exc}", file=sys.stderr)
        chart_w = None

    if chart_w and chart_w > 1080:
        bg_in = ["-loop", "1", "-framerate", "30", "-t", f"{dur:.2f}", "-i", "chart.png"]
        panx = f"-({chart_w - 1080})*t/{dur:.2f}"
        filt = (
            "[1:v]format=rgba,colorchannelmixer=aa=0.55[bgsrc];"
            f"[0:v][bgsrc]overlay=x='{panx}':y=0:shortest=1[bg];"
            "[bg]subtitles=" + ass + "[v]"
        )
    else:
        make_tokens("tokens.png")
        bg_in = ["-loop", "1", "-framerate", "30", "-t", f"{dur:.2f}", "-i", "tokens.png"]
        filt = (
            "[1:v]format=rgba,colorchannelmixer=aa=0.28[bgsrc];"
            "[0:v][bgsrc]overlay=x=0:y='-(mod(t*120,1920))':shortest=1[bg];"
            "[bg]subtitles=" + ass + "[v]"
        )

    subprocess.run(
        ["ffmpeg", "-y", "-f", "lavfi", "-i", grad] + bg_in + ["-i", mp3,
         "-filter_complex", filt,
         "-map", "[v]", "-map", "2:a",
         "-c:v", "libx264", "-r", "30", "-pix_fmt", "yuv420p",
         "-c:a", "aac", "-b:a", "192k",
         "-shortest", out_mp4],
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
    # Si le fichier existe deja (re-run le meme jour), il faut fournir son sha.
    g = requests.get(url, headers=_gh_headers(), params={"ref": "main"}, timeout=30)
    if g.status_code == 200:
        payload["sha"] = g.json().get("sha")
    r = requests.put(url, headers=_gh_headers(), json=payload, timeout=120)
    r.raise_for_status()
    return r.json()["content"]["html_url"]


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
                page = gh_commit_file(f"video/{today}.mp4", f.read(), f"video {today}")
            raw = f"https://raw.githubusercontent.com/{GITHUB_REPOSITORY}/main/video/{today}.mp4"
            video_block = (
                f"🎬 **Vidéo prête à poster :** [Télécharger la vidéo]({raw})\n\n"
                f"_(aperçu dans le navigateur : {page})_"
            )
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
