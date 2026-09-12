#!/usr/bin/env python3
"""Compose les fonds d'univers des huit programmes de Budokai Ichi.

Les images viennent de l'Open Access du Metropolitan Museum of Art : des
estampes japonaises tombées dans le domaine public (CC0). Chacune est passée
en bichromie dans la palette de son programme, recadrée au format attendu par
l'app et assombrie du bas pour que le titre reste lisible par-dessus.

    python3 tools/fetch_universes.py
"""

import json
import urllib.parse
import urllib.request
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageEnhance, ImageOps

BASE = "https://collectionapi.metmuseum.org/public/collection/v1"
OUT = Path("design-v2/images")
TARGET = (1170, 1560)
UA = {"User-Agent": "BudokaiIchi/1.0 (design research; contact via repo)"}

# Les œuvres sont FIGÉES par leur numéro d'objet au Met : la recherche par
# mots-clés dérivait d'une exécution à l'autre et ramenait des sujets sans
# rapport. La requête reste là comme filet si un objet devenait indisponible.
#
# fichier, objet Met, requête de secours, mots du titre, teinte sombre, teinte claire
UNIVERSES = [
    ("saitama",  55736,  "Hokusai Fuji clear weather",    ["fuji", "wind", "weather"], "#2A1004", "#F5C518"),
    ("goku",     45281, "Kuniyoshi dragon",              ["dragon"],                  "#0A2038", "#FF9A3C"),
    ("rocklee",  55735, "Hokusai Ejiri wind",            ["ejiri", "wind"],           "#0A2114", "#7BD389"),
    ("kenshiro", 55743,  "Kuniyoshi warriors battle",     ["ghost", "taira", "warrior"], "#240606", "#E0B44A"),
    ("ichigo",   73623,  "Yoshitoshi moon",               ["moon"],                    "#0A0A0C", "#E8665A"),
    ("minato",   36967,  "Hiroshige sudden shower",       ["shower", "rain", "storm"], "#101E3C", "#F5D547"),
    ("levi",     55628,  "Hiroshige snow mountain gorge", ["snow", "gorge", "pass"],   "#131A15", "#B9C4BC"),
    ("luffy",    39799,  "Hokusai great wave Kanagawa",   ["wave"],                    "#3A0A0A", "#F6C453"),
]

# Département 6 = Asian Art. Sans ce filtre la recherche ramène des objets
# d'autres civilisations dès que le mot-clé est générique.
ASIAN_ART = 6
seen_objects = set()


def fetch_json(url):
    request = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def find_object(query, keywords):
    """Estampe du domaine public dont le titre confirme le sujet cherché.

    La recherche du Met classe par pertinence lexicale, pas par sujet : sans
    vérification du titre on récupère un vase mésoaméricain pour « storm ».
    """
    url = (f"{BASE}/search?isPublicDomain=true&hasImages=true"
           f"&departmentId={ASIAN_ART}&q=" + urllib.parse.quote(query))
    ids = fetch_json(url).get("objectIDs") or []

    fallback = None
    for object_id in ids[:30]:
        if object_id in seen_objects:
            continue
        try:
            obj = fetch_json(f"{BASE}/objects/{object_id}")
        except Exception:
            continue
        if not (obj.get("primaryImage") and obj.get("isPublicDomain")):
            continue
        # une estampe remplit le cadre ; un objet photographié sur fond neutre, non
        classification = (obj.get("classification") or "").lower()
        if "print" not in classification and "painting" not in classification:
            continue
        # un rouleau suspendu est photographié avec son montage : deux bandes
        # verticales de soie encadrent l'image et traversent tout le fond
        medium = (obj.get("medium") or "").lower() + " " + (obj.get("objectName") or "").lower()
        if "hanging scroll" in medium or "handscroll" in medium or "album leaf" in medium:
            continue
        title = (obj.get("title") or "").lower()
        if any(word in title for word in keywords):
            seen_objects.add(object_id)
            return obj
        if fallback is None:
            fallback = obj
    if fallback is not None:
        seen_objects.add(fallback.get("objectID"))
    return fallback


def download_image(obj):
    url = obj.get("primaryImageSmall") or obj["primaryImage"]
    request = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(request, timeout=60) as response:
        data = response.read()
    image = Image.open(BytesIO(data))
    # une image trop petite serait floue une fois agrandie : on reprend la grande
    if min(image.size) < 900 and obj.get("primaryImage") and obj["primaryImage"] != url:
        request = urllib.request.Request(obj["primaryImage"], headers=UA)
        with urllib.request.urlopen(request, timeout=90) as response:
            image = Image.open(BytesIO(response.read()))
    return image.convert("RGB")


def trim_scan_edges(image, ratio=0.06):
    """Retire la bordure de numérisation : passe-partout, règle de couleurs,
    liseré de papier. Sans ça une bande grise ou une échelle chromatique
    traverse le fond."""
    dx, dy = round(image.width * ratio), round(image.height * ratio)
    return image.crop((dx, dy, image.width - dx, image.height - dy))


def cover_crop(image, size):
    """Remplit le cadre sans déformer, en gardant le haut de l'image."""
    target_w, target_h = size
    scale = max(target_w / image.width, target_h / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)
    left = (resized.width - target_w) // 2
    top = min((resized.height - target_h) // 2, round(resized.height * 0.12))
    return resized.crop((left, top, left + target_w, top + target_h))


def bottom_fade(image, dark):
    """Dégradé vers le noir sur la moitié basse : le titre passera dessus."""
    width, height = image.size
    mask = Image.new("L", (1, height), 0)
    start = int(height * 0.42)
    for y in range(start, height):
        t = (y - start) / (height - start)
        mask.putpixel((0, y), int(255 * (t ** 1.5)))
    mask = mask.resize((width, height))
    return Image.composite(Image.new("RGB", (width, height), dark), image, mask)


def build(name, pinned, query, keywords, dark, light):
    obj = fetch_json(f"{BASE}/objects/{pinned}") if pinned else find_object(query, keywords)
    if obj is None:
        return None
    image = download_image(obj)
    grey = ImageOps.autocontrast(trim_scan_edges(image).convert("L"), cutoff=2)
    duotone = ImageOps.colorize(grey, black=dark, white=light)
    # le papier ancien est clair : sans cet assombrissement, un titre blanc
    # posé par-dessus devient illisible
    duotone = ImageEnhance.Brightness(duotone).enhance(0.86)
    framed = bottom_fade(cover_crop(duotone, TARGET), dark)

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{name}.jpg"
    for quality in (86, 80, 72, 64):
        framed.save(path, "JPEG", quality=quality, optimize=True, progressive=True)
        if path.stat().st_size <= 800_000:
            break
    return {
        "fichier": path.name,
        "titre": obj.get("title") or "—",
        "artiste": obj.get("artistDisplayName") or "Anonyme",
        "date": obj.get("objectDate") or "—",
        "objectID": obj.get("objectID"),
        "inventaire": obj.get("objectNumber"),
        "lien": obj.get("objectURL"),
        "licence": "Domaine public (The Met, Open Access CC0)",
        "poids_ko": round(path.stat().st_size / 1024),
    }


if __name__ == "__main__":
    credits = []
    for name, pinned, query, keywords, dark, light in UNIVERSES:
        try:
            info = build(name, pinned, query, keywords, dark, light)
        except Exception as error:
            print(f"  échec  {name}: {error}")
            continue
        if info is None:
            print(f"  rien trouvé pour {name} ({query})")
            continue
        credits.append(info)
        print(f"  {info['fichier']:<14} {info['poids_ko']:>4} Ko  {info['artiste']} — {info['titre'][:52]}")
    (OUT / "credits.json").write_text(json.dumps(credits, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\n{len(credits)} fonds composés")
