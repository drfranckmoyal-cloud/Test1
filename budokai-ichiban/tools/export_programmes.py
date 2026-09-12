#!/usr/bin/env python3
"""Sort les neuf programmes en un document lisible.

Lit les données embarquées dans l'app — définitions, séances écrites par le
coach, narration — et n'invente rien. Remplace l'ancien export, qui compilait
le générateur en ligne droite désormais retiré.

    python3 tools/export_programmes.py [fichier.md]
"""

import json, os, sys, datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROGRAMS = os.path.join(ROOT, "BudokaiIchi", "Programs")
NARRATION = os.path.join(ROOT, "BudokaiIchi", "Narration")

NAMES = {"saitama":"Saitama","naruto":"Naruto","rocklee":"Rock Lee","kenshiro":"Kenshiro",
         "ichigo":"Ichigo","minato":"Minato","levi":"Levi","luffy":"Luffy","goku":"Goku"}
ORDER = ["saitama","naruto","goku","rocklee","kenshiro","levi","ichigo","minato","luffy"]

def load(path):
    return json.load(open(path, encoding="utf-8")) if os.path.exists(path) else None

def amount(e):
    unit, sets, per, value = e["unit"], e.get("sets"), e.get("perSet"), e.get("value")
    def fmt(v):
        if unit == "reps":    return f"{v} répétitions"
        if unit == "seconds":
            return f"{v // 60} min" if v >= 60 and v % 60 == 0 else (
                   f"{v // 60} min {v % 60} s" if v >= 60 else f"{v} s")
        if unit == "meters":
            return f"{v/1000:.1f} km".replace(".", ",") if v >= 1000 else f"{v} m"
        return f"{v} kg"
    if sets and per and sets > 1: return f"{sets} séries de {fmt(per)}"
    return fmt(value if value is not None else (sets or 1) * (per or 0))

def intensity(e):
    bits = []
    if e.get("rir") is not None: bits.append(f"{e['rir']} en réserve")
    if e.get("rpe") is not None: bits.append(f"effort {e['rpe']}/10")
    if e.get("tempo"): bits.append(f"tempo {e['tempo']}")
    if e.get("restSeconds"): bits.append(f"repos {e['restSeconds']} s")
    return " · ".join(bits)

POLICY = {"continuous":"en une seule fois","dayCumulative":"réparti sur la journée",
          "structuredSession":"en séance"}

out = []
def w(line=""): out.append(line)

today = datetime.date.today().strftime("%d/%m/%Y")
w("# Budokai Ichiban — les neuf programmes")
w()
w(f"Contenu extrait des données de l'application le {today}.")
w()
w("Les séances sont décrites **par semaine type** : une par jalon et par")
w("fréquence. Le moteur la répète et lui applique la progression indiquée à")
w("mesure que l'on avance dans le jalon.")
w()

w("## Vue d'ensemble")
w()
w("| Programme | Qualité | Jalons | Fréquences | Séances écrites | Récits | Combat final |")
w("|---|---|---|---|---|---|---|")
for pid in ORDER:
    d = load(f"{PROGRAMS}/{pid}.def.json")
    if not d: continue
    ses = load(f"{PROGRAMS}/{pid}.sessions.json")
    nar = load(f"{NARRATION}/{pid}.json")
    freqs = ", ".join(sorted(d["scheduling"]["templates"], key=int))
    written = f"{len(ses['weeks'])} semaines type" if ses else ("moteur dédié" if pid == "saitama" else "à écrire")
    w(f"| {NAMES[pid]} | {d['quality']} | {len(d['stages'])} | {freqs} | {written} "
      f"| {len(nar['narrativeSessions']) if nar else 0} | {d['boss']['title'] if d.get('boss') else '—'} |")
w()

for pid in ORDER:
    d = load(f"{PROGRAMS}/{pid}.def.json")
    if not d: continue
    ses = load(f"{PROGRAMS}/{pid}.sessions.json")
    nar = load(f"{NARRATION}/{pid}.json")
    sch = d["scheduling"]

    w(); w("---"); w()
    w(f"# {NAMES[pid]} — {d['quality']}")
    w()
    w(f"**{sch['min']} séances minimum · {sch['recommended']} recommandé · "
      f"{sch['max']} maximum.** Séance clé : {sch['keySessionLabel']}.")
    w()

    # les semaines type par fréquence
    for freq in sorted(sch["templates"], key=int):
        titles = " · ".join(s["title"] for s in sch["templates"][freq])
        w(f"À {freq} séances : {titles}.")
    w()

    for index, stage in enumerate(d["stages"], 1):
        w(f"## Jalon {index} — {stage['title']}")
        w()
        w(f"*{stage['goal']}*")
        w()
        if stage.get("benchmark"): w(f"**Repère de sortie :** {stage['benchmark']}")
        for item in stage.get("exit", []): w(f"- {item}")
        w(f"\nDurée : {stage['weeksMin']} à {stage['weeksMax']} semaines.")
        w()

        if nar:
            beats = [s for s in nar["narrativeSessions"] if s.get("stage") == stage["key"]]
            if beats:
                w(f"**L'histoire** — {beats[0]['storyRecap']}")
                w()

        if ses:
            weeks = [x for x in ses["weeks"] if x["stage"] == stage["key"]]
            for week in sorted(weeks, key=lambda x: x["frequency"]):
                w(f"### Semaine type à {week['frequency']} séances")
                if week.get("progression"):
                    pr = week["progression"]
                    grow = f", +{int(pr['perWeek']*100)} % par semaine" if pr.get("perWeek") else ""
                    w(f"\n*Progression : {pr['rule']}{grow}. {pr.get('note','')}*")
                w()
                for s in sorted(week["sessions"], key=lambda x: x["slot"]):
                    w(f"**{s['slot']+1}. {s['title']}**")
                    w()
                    for e in s["exercises"]:
                        role = {"warmup":"échauffement","cooldown":"retour au calme",
                                "assistance":"assistance"}.get(e["role"], "")
                        line = f"- {e['name']} — {amount(e)}"
                        extra = [x for x in [intensity(e), role,
                                 POLICY.get(e.get("policy","")) if e.get("policy") != "structuredSession" else ""] if x]
                        if extra: line += f" *({', '.join(extra)})*"
                        w(line)
                    w()

    if d.get("boss"):
        b = d["boss"]
        w(f"## Combat final — {b['title']}")
        w()
        w(b["summary"]); w()
        for c in b["components"]:
            w(f"- **{c['name']}** : {amount({'unit':c['unit'],'value':c['value']})} "
              f"*({POLICY.get(c['policy'],'')})*")
        w()
        w("**Conditions d'accès :**")
        for r in b["requirements"]: w(f"- {r}")
        w()
    if d.get("superRank"):
        w(f"**Mode supérieur :** {d['superRank']['name']}"); w()

path = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser(
    "~/Desktop/Budokai Ichiban — les neuf programmes.md")
open(path, "w", encoding="utf-8").write("\n".join(out))
print(f"écrit : {path} — {len('\n'.join(out))} caractères")
