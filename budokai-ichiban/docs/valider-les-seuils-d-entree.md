# BUDOKAI ICHIBAN — VALIDATION DES SEUILS D'ENTRÉE

Tu es **préparateur physique**. On ne te demande pas d'écrire des séances : elles
existent. On te demande de vérifier **une seule chose**, et de la corriger si elle
est fausse.

---

## 1. Le problème qu'on vient de corriger

Chaque programme mesure le pratiquant au lancement — pompes, tractions, chrono sur
10 m, amplitude de cheville. Jusqu'ici cette mesure était **jetée** : tout le monde
démarrait au même échelon, écrit en dur. Celui qui fait trente pompes commençait
comme celui qui en fait trois.

C'est réparé : chaque mesure porte maintenant une **table de seuils** qui dit à quel
échelon de l'échelle elle place le pratiquant.

**Ces tables ont été écrites par un intégrateur, pas par un préparateur.** Elles sont
mécaniquement cohérentes — un test de tractions se lit sur une échelle de tractions —
mais elles n'ont jamais été validées sportivement. C'est ton travail.

---

## 2. Ce que tu ne dois pas rediscuter

- Les **échelles** elles-mêmes : leur contenu, leur ordre, leur nombre d'échelons.
- Les **jalons**, les **combats finaux**, les **récompenses**, la **narration**.
- Les **noms** des exercices : ils viennent d'être simplifiés exprès.
- Le **moteur** : progression, décharges, adaptation au ressenti.

Tu ne touches qu'aux **chiffres des tables de seuils**.

---

## 3. Ce que tu dois vérifier, test par test

Pour chaque table ci-dessous, réponds à quatre questions :

1. **Le seuil est-il au bon endroit ?** Un pratiquant qui donne cette mesure doit
   arriver sur un échelon qui représente **un vrai défi**, ni un échauffement, ni un
   mur. La règle produit est : *on ne commence jamais au niveau 1 par défaut, on
   commence au premier niveau qui reste exigeant.*
2. **Y a-t-il un saut dangereux ?** Un seuil trop généreux peut envoyer quelqu'un sur
   un mouvement qu'il ne maîtrise pas techniquement. Signale-le.
3. **Y a-t-il un plafond mal placé ?** Certains échelons hauts appartiennent au
   **dernier jalon** du programme et ne doivent pas servir de point d'entrée, même à
   un pratiquant avancé. Si tu en repères un, dis-le.
4. **Manque-t-il un palier ?** Une table à trois seuils sur une échelle de neuf
   échelons laisse peut-être des trous.

---

## 4. Ce dont tu dois tenir compte

La mesure seule ne suffit pas. L'app connaît aussi, au lancement :

- la fréquence choisie ;
- les jours disponibles ;
- la durée de séance visée ;
- les autres mesures du même programme.

Si tu penses qu'un seuil ne devrait pas s'appliquer sans croiser une autre donnée,
**dis-le en une phrase** plutôt que de l'ignorer.

---

## 5. Le format de ta réponse

Un objet JSON par programme, **sans texte autour**, suivi de tes remarques en clair
dans un second message si tu en as.

```json
{
  "program": "kenshiro",
  "tests": [
    {
      "id": "pull",
      "verdict": "corrigé",
      "entry": [
        { "atLeast": 0, "level": 2 },
        { "atLeast": 1, "level": 5 },
        { "atLeast": 3, "level": 6 },
        { "atLeast": 6, "level": 7 },
        { "atLeast": 9, "level": 8 }
      ],
      "why": "Trois tractions strictes ne suffisent pas à tenir un volume à cinq."
    },
    { "id": "push", "verdict": "validé" }
  ]
}
```

**`verdict`** — `validé`, `corrigé` ou `douteux`.
Avec `validé`, n'écris pas de table : l'existante est gardée.
Avec `douteux`, explique ce qui te manque pour trancher.

**`atLeast`** — la mesure atteint au moins cette valeur.
**`atMost`** — pour les chronos : la mesure ne dépasse pas cette valeur.
Une table n'utilise qu'une des deux formes, jamais les deux.

**`level`** — le numéro d'échelon, de 1 au nombre d'échelons de l'échelle. Il est
donné pour chaque échelon ci-dessous.

---

## 6. Les données

Pour chaque programme : ses échelles numérotées, puis ses tests et leur table
actuelle.


---

## Goku — `goku`

### Les échelles

**Squat** · `goku.squat` — 6 échelons

1. **Squat** — Cuisses parallèles, talons au sol.
2. **Squat lesté** *(Bear hug squat)* — Tiens le sac serré contre la poitrine.
3. **Squat lesté** *(Front loaded squat)* — Charge tenue devant, coudes hauts.
4. **Squat lesté** *(Tempo squat)* — Descente lente : 3 secondes.
5. **Fente lestée** *(Split squat chargé)* — Un pied devant, un pied derrière, genou arrière vers le sol.
6. **Fente lestée** *(Bulgarian split squat)* — Pied arrière posé sur une chaise.

**Hinge** · `goku.hinge` — 6 échelons

1. **Soulevé de terre à vide** *(Hip hinge)* — Pousse les hanches vers l'arrière, dos plat.
2. **Soulevé de terre avec sac** *(Bag deadlift)* — Sac au sol, tu le ramasses en poussant les hanches en arrière.
3. **Soulevé de terre avec sac** *(Romanian deadlift)* — Jambes presque tendues, le sac descend le long des cuisses.
4. **Soulevé de terre avec sac** *(Tempo RDL)* — Descente lente : 3 secondes.
5. **Soulevé de terre avec sac** *(Staggered RDL)* — Un pied légèrement derrière l'autre.
6. **Soulevé de terre avec sac** *(Single-leg RDL)* — Une jambe part en arrière pendant que le buste descend.

**Push** · `goku.push` — 6 échelons

1. **Pompe inclinée** — Mains sur une table ou un banc : plus la surface est haute, plus c'est facile.
2. **Pompe** — Corps gainé, poitrine près du sol.
3. **Développé au sol avec sac** *(Bag floor press)* — Allongé sur le dos, tu pousses le sac vers le plafond.
4. **Pompe** *(Tempo push-up)* — Descente lente : 3 secondes.
5. **Pompe pieds surélevés** — Pieds sur une chaise.
6. **Pompe lestée** — Sac posé en haut du dos, bien calé.

**Pull** · `goku.pull` — 6 échelons

1. **Tirage avec sac** *(Light bag row)* — Sac léger, buste penché, dos plat.
2. **Tirage avec sac** *(Bag row)* — Buste penché, tu tires le sac vers le ventre.
3. **Tirage à un bras** *(One-arm supported row)* — Main libre appuyée sur une chaise.
4. **Tirage avec sac** *(Tempo row)* — Retour lent : 3 secondes.
5. **Tirage à un bras** *(Heavy one-arm row)* — Charge plus lourde, même position.
6. **Tirage à un bras** *(Offset row)* — Charge tenue loin du corps, plus dure à tenir.

**Carry** · `goku.carry` — 6 échelons

1. **Maintien avec charge** *(Bear hug hold)* — Debout, le sac serré contre la poitrine.
2. **Marche avec charge** *(Bear hug carry)* — Tiens le sac contre la poitrine.
3. **Marche avec charge** *(Backpack walk)* — Sac sur le dos, bien sanglé.
4. **Marche avec charge** *(Suitcase carry)* — Porte la charge d'un seul côté, sans pencher.
5. **Marche avec charge** *(Offset carry)* — Une charge d'un côté, une autre plus légère de l'autre.
6. **Marche avec charge** *(Heavy carry)* — Charge lourde, distance plus courte.

**Core** · `goku.core` — 6 échelons

1. **Abdos bras-jambe opposés** *(Dead bug)* — Sur le dos, tu tends le bras et la jambe opposés sans creuser le dos.
2. **Planche** — Appui sur les avant-bras, corps aligné.
3. **Gainage latéral** *(Side plank)* — Sur un coude, bassin haut.
4. **Marche sur place avec charge** *(Bear hug march)* — Sac contre la poitrine, tu montes les genoux.
5. **Maintien avec charge** *(Suitcase hold)* — Debout, une charge dans une main, épaules droites.
6. **Marche sur place avec charge** *(Offset march)* — Charge d'un seul côté, tu montes les genoux sans pencher.

### Les tests et leurs seuils actuels

**`squat`** — Jambes, en répétitions, maximum saisissable 20
> Consigne au pratiquant : « Trouve la variante et la charge qui te permettent 8 à 12 répétitions avec 2 à 3 en réserve. »
>
> Échelle visée : `goku.squat` (6 échelons)
> Renseigne aussi : `goku.core`
>
> - au moins **0** → échelon **1**
> - au moins **10** → échelon **2**
> - au moins **20** → échelon **3**

**`hinge`** — Chaîne postérieure, en répétitions, maximum saisissable 20
> Consigne au pratiquant : « Choisis une charge permettant 8 à 12 répétitions propres avec 2 à 3 en réserve. »
>
> Échelle visée : `goku.hinge` (6 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **8** → échelon **2**
> - au moins **15** → échelon **3**

**`push`** — Poussée, en répétitions, maximum saisissable 30
> Consigne au pratiquant : « Sélectionne la variante qui permet 6 à 12 répétitions propres avec 2 à 3 en réserve. »
>
> Échelle visée : `goku.push` (6 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **5** → échelon **2**
> - au moins **15** → échelon **3**
> - au moins **25** → échelon **4**

**`pull`** — Tirage, en répétitions, maximum saisissable 20
> Consigne au pratiquant : « Sélectionne la charge/variante qui permet 8 à 12 répétitions propres avec 2 à 3 en réserve. »
>
> Échelle visée : `goku.pull` (6 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **5** → échelon **2**
> - au moins **12** → échelon **3**

**`carry`** — Transport chargé, en mètres, maximum saisissable 200
> Consigne au pratiquant : « Choisis une charge permettant 30 à 60 mètres avec posture stable et RPE maximal 6. »
>
> Échelle visée : `goku.carry` (6 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **50** → échelon **2**
> - au moins **100** → échelon **3**


---

## Ichigo — `ichigo`

### Les échelles

**Pompes** · `ichigo.push` — 7 échelons

1. **Pompe inclinée** — Mains sur une table ou un banc.
2. **Pompe** — Continue
3. **Pompe** *(Volume sets)* — Plus de séries, mêmes répétitions.
4. **Pompe** *(Density)* — Mêmes séries, moins de repos.
5. **Pompe — série longue** — 25 répétitions d'affilée.
6. **Pompe — série longue** — 40 répétitions d'affilée.
7. **Pompe — série longue** — 50 répétitions d'affilée.

**Tractions** · `ichigo.pull` — 7 échelons

1. **Suspension à la barre** *(Dead hang)* — Bras tendus, épaules actives.
2. **Suspension, épaules actives** *(Scap pull)* — Sans plier les bras, tu remontes les épaules.
3. **Traction assistée** — Un pied posé sur une chaise pour t'aider.
4. **Traction négative** — Tu pars en haut et tu descends le plus lentement possible.
5. **Traction** — 3 répétitions strictes.
6. **Traction** — 6 répétitions strictes.
7. **Traction** — 10 répétitions strictes.

**Squats** · `ichigo.squat` — 4 échelons

1. **Squat sur chaise** *(Sit-to-stand)* — Tu t'assieds et tu te relèves sans élan.
2. **Squat** — Standard
3. **Squat** *(Volume)* — Plus de séries.
4. **Squat** — 100 répétitions dans la journée, à répartir.

**Abdos** · `ichigo.abs` — 3 échelons

1. **Abdos** *(Curl-up)* — Épaules décollées, bas du dos plaqué.
2. **Abdos** *(Volume)* — Plus de séries.
3. **Abdos** — 200 répétitions dans la journée, à répartir.

**Course 5 km** · `ichigo.run` — 5 échelons

1. **Course et marche** *(Run/walk)* — Alterne course facile et marche.
2. **Course facile** — 20 minutes sans marcher.
3. **Course facile** — 30 minutes sans marcher.
4. **Course facile** — 4 km sans marcher.
5. **Course facile** — 5 km sans marcher.

### Les tests et leurs seuils actuels

**`push`** — Pompes, en répétitions, maximum saisissable 40
> Consigne au pratiquant : « Max propre avec arrêt à la première dégradation. »
>
> Échelle visée : `ichigo.push` (7 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **5** → échelon **2**
> - au moins **15** → échelon **3**
> - au moins **25** → échelon **5**
> - au moins **40** → échelon **6**
> - au moins **50** → échelon **7**

**`pull`** — Tractions, en répétitions, maximum saisissable 15
> Consigne au pratiquant : « Max strict sans kipping. »
>
> Échelle visée : `ichigo.pull` (7 échelons)
>
> - au moins **0** → échelon **2**
> - au moins **1** → échelon **4**
> - au moins **3** → échelon **5**
> - au moins **6** → échelon **6**
> - au moins **10** → échelon **7**

**`squat`** — Squats, en répétitions, maximum saisissable 60
> Consigne au pratiquant : « Cap 60 reps propres. »
>
> Échelle visée : `ichigo.squat` (4 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **10** → échelon **2**
> - au moins **30** → échelon **3**

**`abs`** — Abdos, en répétitions, maximum saisissable 60
> Consigne au pratiquant : « Curl-up contrôlé, cap 60. »
>
> Échelle visée : `ichigo.abs` (3 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **10** → échelon **2**
> - au moins **30** → échelon **3**

**`easyDistance`** — Ta distance facile, en mètres, maximum saisissable 42195
> Consigne au pratiquant : « Pas ton record : la distance que tu sais courir aujourd'hui à allure confortable, sans marcher. »
> Question posée : « Quelle distance peux-tu courir facilement aujourd'hui, sans marcher ? »
> Réponses : Je ne peux pas encore courir 2 km facilement (= 1000) / 2 km (= 2000) / 5 km (= 5000) / 7 km (= 7000) / 10 km ou plus (= 10000)
>
> Échelle visée : `ichigo.run` (5 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **2000** → échelon **2**
> - au moins **5000** → échelon **4**
> - au moins **7000** → échelon **5**
> - au moins **10000** → échelon **5**


---

## Kenshiro — `kenshiro`

### Les échelles

**Push** · `kenshiro.push` — 9 échelons

1. **Pompe au mur** — Mains au mur, debout.
2. **Pompe inclinée** — Mains sur une table ou un banc.
3. **Pompe** — Amplitude complète
4. **Pompe pieds surélevés** — Pieds sur une chaise.
5. **Pompe archer** — Un bras tendu sur le côté, l'autre travaille.
6. **Pompe à un bras assistée** *(Assisted one-arm push-up)* — L'autre main posée sur un support surélevé.
7. **Pompe à un bras** *(One-arm eccentric)* — Tu descends lentement sur un bras, tu remontes à deux.
8. **Pompe à un bras** *(One-arm push-up)* — Une répétition complète.
9. **Pompe à un bras** *(One-arm volume)* — Plusieurs répétitions par côté.

**Pull** · `kenshiro.pull` — 8 échelons

1. **Suspension à la barre** *(Dead hang)* — Bras tendus, épaules actives.
2. **Suspension, épaules actives** *(Scap pull)* — Sans plier les bras, tu remontes les épaules.
3. **Traction assistée** *(Foot-assisted pull-up)* — Un pied posé pour t'aider.
4. **Traction négative** — Tu pars en haut et tu descends lentement.
5. **Traction** — 1 répétition stricte.
6. **Traction** — 3 répétitions strictes.
7. **Traction** — 5 répétitions strictes.
8. **Traction** — 8 répétitions strictes.

**Squat unilatéral** · `kenshiro.squat` — 9 échelons

1. **Squat sur chaise** *(Sit-to-stand)* — Tu t'assieds et tu te relèves sans élan.
2. **Squat** — Bilatéral
3. **Fente** *(Split squat)* — Un pied devant, un pied derrière.
4. **Squat sur une jambe** *(Box pistol)* — Tu t'assieds sur une chaise sur une seule jambe.
5. **Squat sur une jambe** *(Eccentric pistol)* — Tu descends lentement sur une jambe, tu remontes à deux.
6. **Squat sur une jambe** *(Counterbalanced pistol)* — Bras tendus devant pour l'équilibre.
7. **Squat sur une jambe** *(Pistol squat)* — Descente complète, sans appui.
8. **Squat sur une jambe** *(Pistol volume)* — Plusieurs répétitions par jambe.
9. **Squat sur une jambe** *(Pistol tempo)* — Descente lente : 3 secondes.

**Core** · `kenshiro.core` — 5 échelons

1. **Abdos bras-jambe opposés** *(Dead bug)* — Sur le dos, bras et jambe opposés, sans creuser le dos.
2. **Planche** — Appui sur les avant-bras, corps aligné.
3. **Gainage en cuillère, genoux repliés** *(Hollow tuck)* — Sur le dos, bas du dos plaqué, genoux vers la poitrine.
4. **Gainage en cuillère** *(Hollow hold)* — Sur le dos, bras et jambes tendus, bas du dos plaqué.
5. **Montée de genoux suspendu** *(Hanging knee raise)* — Suspendu à la barre, tu montes les genoux.

### Les tests et leurs seuils actuels

**`push`** — Poussée, en répétitions, maximum saisissable 20
> Consigne au pratiquant : « Trouve une variante à 5–12 reps avec 2–3 RIR. »
>
> Échelle visée : `kenshiro.push` (9 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **1** → échelon **2**
> - au moins **5** → échelon **3**
> - au moins **15** → échelon **4**
> - au moins **25** → échelon **5**

**`pull`** — Traction, en répétitions, maximum saisissable 12
> Consigne au pratiquant : « Trouve une variante à 3–8 reps avec 2–3 RIR. »
>
> Échelle visée : `kenshiro.pull` (8 échelons)
>
> - au moins **0** → échelon **2**
> - au moins **1** → échelon **5**
> - au moins **2** → échelon **6**
> - au moins **4** → échelon **7**
> - au moins **7** → échelon **8**

**`squat`** — Jambes, en répétitions, maximum saisissable 15
> Consigne au pratiquant : « Trouve une variante unilatérale propre à 5–10 reps/côté. »
>
> Échelle visée : `kenshiro.squat` (9 échelons)
>
> - au moins **0** → échelon **2**
> - au moins **10** → échelon **3**
> - au moins **15** → échelon **4**

**`core`** — Tronc, en secondes, maximum saisissable 90
> Consigne au pratiquant : « Choisis une variante tenable 20–40 s avec qualité good. »
>
> Échelle visée : `kenshiro.core` (5 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **20** → échelon **2**
> - au moins **40** → échelon **3**
> - au moins **60** → échelon **4**


---

## Levi — `levi`

### Les échelles

**Anti-extension** · `levi.antiExtension` — 5 échelons

1. **Abdos bras-jambe opposés** *(Dead bug)* — Sur le dos, bras et jambe opposés, sans creuser le dos.
2. **Planche** *(Forearm plank)* — Appui sur les avant-bras, corps aligné.
3. **Gainage en cuillère, genoux repliés** *(Hollow tuck)* — Bas du dos plaqué, genoux vers la poitrine.
4. **Gainage en cuillère** *(One-leg hollow)* — Une jambe tendue, l'autre repliée.
5. **Gainage en cuillère** *(Hollow body)* — Bras et jambes tendus, bas du dos plaqué.

**Lateral** · `levi.lateral` — 4 échelons

1. **Gainage latéral** — Appui sur le coude et les genoux.
2. **Gainage latéral** — Tenue courte, bassin haut.
3. **Gainage latéral** — Jambes tendues, bassin haut.
4. **Gainage latéral** *(Star plank)* — Jambe du dessus levée.

**Cross-body** · `levi.cross` — 5 échelons

1. **Bras et jambe opposés à quatre pattes** *(Bird dog)* — À quatre pattes, tu tends le bras et la jambe opposés.
2. **Touchés d'épaule** *(Bear shoulder tap)* — Genoux à quelques centimètres du sol, tu touches l'épaule opposée.
3. **Touchés d'épaule** *(Shoulder tap)* — En planche, pieds écartés, tu touches l'épaule opposée.
4. **Touchés d'épaule** *(Shoulder tap)* — En planche, pieds à largeur de hanches.
5. **Touchés d'épaule** *(Narrow shoulder tap)* — Pieds joints : le bassin ne doit pas tourner.

**Posterior** · `levi.posterior` — 4 échelons

1. **Pont fessier** *(Glute bridge)* — Sur le dos, tu montes le bassin.
2. **Pont fessier sur une jambe** — Une jambe tendue en l'air.
3. **Ischios en glissé** *(Hamstring walkout)* — Depuis le pont, tu éloignes les talons petit à petit.
4. **Planche inversée** *(Reverse plank)* — Assis, mains derrière, tu montes le bassin.

**Hang** · `levi.hang` — 5 échelons

1. **Suspension assistée** — Un pied posé pour alléger.
2. **Suspension à la barre** *(Dead hang)* — 20 à 30 secondes.
3. **Suspension à la barre** *(Dead hang)* — 30 à 45 secondes.
4. **Suspension à la barre** *(Dead hang)* — 60 secondes.
5. **Suspension, épaules actives** *(Active hang)* — Épaules basses et serrées, bras tendus.

**Pull** · `levi.pull` — 6 échelons

1. **Suspension, épaules actives** *(Scap pull)* — Sans plier les bras, tu remontes les épaules.
2. **Traction assistée** — Un pied posé pour t'aider.
3. **Traction négative** — Tu pars en haut et tu descends lentement.
4. **Traction** — 1 répétition stricte.
5. **Traction** — 3 répétitions strictes.
6. **Traction** — 5 répétitions strictes.

### Les tests et leurs seuils actuels

**`hollow`** — Anti-extension, en secondes, maximum saisissable 60
> Consigne au pratiquant : « Choisis une variante tenable 20–40 s sans perdre la position. »
>
> Échelle visée : `levi.antiExtension` (5 échelons)
> Renseigne aussi : `levi.cross`
>
> - au moins **0** → échelon **1**
> - au moins **10** → échelon **2**
> - au moins **20** → échelon **3**
> - au moins **35** → échelon **4**
> - au moins **50** → échelon **5**

**`side`** — Lateral, en secondes, maximum saisissable 60
> Consigne au pratiquant : « Teste chaque côté séparément. »
>
> Échelle visée : `levi.lateral` (4 échelons)
> Renseigne aussi : `levi.posterior`
>
> - au moins **0** → échelon **1**
> - au moins **15** → échelon **2**
> - au moins **30** → échelon **3**
> - au moins **45** → échelon **4**

**`hang`** — Hang, en secondes, maximum saisissable 60
> Consigne au pratiquant : « Suspension confortable, cap 60 s. »
>
> Échelle visée : `levi.hang` (5 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **10** → échelon **2**
> - au moins **25** → échelon **3**
> - au moins **40** → échelon **4**
> - au moins **60** → échelon **5**

**`pull`** — Pull-up, en répétitions, maximum saisissable 12
> Consigne au pratiquant : « Arrête dès dégradation technique. »
>
> Échelle visée : `levi.pull` (6 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **1** → échelon **4**
> - au moins **2** → échelon **5**
> - au moins **4** → échelon **6**


---

## Luffy — `luffy`

### Les échelles

**Cheville** · `luffy.ankle` — 4 échelons

1. **Mobilité cheville** *(Ankle rocks)* — À genoux ou debout, tu avances le genou au-dessus des orteils.
2. **Mobilité cheville** *(Knee-to-wall)* — Genou vers le mur, talon au sol.
3. **Mobilité cheville** *(Soleus stretch)* — Genou fléchi, talon au sol.
4. **Mobilité cheville** *(Active dorsiflexion)* — Tu tires activement la pointe du pied vers toi.

**Hanche / squat** · `luffy.hip` — 5 échelons

1. **Squat profond** — Tiens-toi à un appui pour descendre bas.
2. **Squat profond** *(Squat pry)* — En bas du squat, tu pousses les genoux vers l'extérieur.
3. **Mobilité hanche** *(90/90)* — Assis, une jambe devant à 90°, l'autre sur le côté.
4. **Squat latéral** *(Cossack squat)* — Tu descends d'un côté, l'autre jambe tendue.
5. **Squat profond** — Talons au sol, sans appui.

**Postérieur** · `luffy.posterior` — 4 échelons

1. **Mobilité ischios** — Sur le dos, une jambe tendue vers le plafond.
2. **Mobilité ischios** *(Dynamic leg raise)* — Mouvement contrôlé, sans à-coups.
3. **Mobilité ischios** *(Hinge drill)* — Debout, hanches en arrière, dos plat.
4. **Mobilité ischios** *(Active straight leg raise)* — L'autre jambe reste au sol.

**Épaule** · `luffy.shoulder` — 4 échelons

1. **Mobilité épaules** *(Wall slide)* — Dos au mur, tu montes les bras en gardant le contact.
2. **Mobilité épaules** *(Lat stretch)* — Bras tendus devant, tu pousses la poitrine vers le sol.
3. **Mobilité épaules** *(Wall flexion)* — Côtes basses : ne creuse pas le dos.
4. **Mobilité épaules** *(Lift-off)* — À plat ventre, bras tendus devant, tu les décolles.

**Thorax** · `luffy.thoracic` — 4 échelons

1. **Rotation du buste** *(Open book)* — Allongé sur le côté, tu ouvres le bras du dessus.
2. **Rotation du buste** *(Quadruped rotation)* — Une main derrière la tête, tu ouvres le coude vers le plafond.
3. **Rotation du buste** *(Half-kneeling rotation)* — Un genou au sol, tu tournes le buste.
4. **Rotation du buste** *(Active rotation hold)* — Tu tiens la rotation quelques secondes.

### Les tests et leurs seuils actuels

**`ankle`** — Knee-to-wall, en centimètres, maximum saisissable 20
> Consigne au pratiquant : « Talon au sol, genou vers le mur : mesure l'écart gros orteil-mur en centimètres. »
>
> Échelle visée : `luffy.ankle` (4 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **5** → échelon **2**
> - au moins **8** → échelon **3**
> - au moins **12** → échelon **4**

**`squat`** — Deep squat, en secondes, maximum saisissable 60
> Consigne au pratiquant : « Tiens la position confortable, talons au sol. »
>
> Échelle visée : `luffy.hip` (5 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **10** → échelon **2**
> - au moins **30** → échelon **3**
> - au moins **45** → échelon **4**
> - au moins **60** → échelon **5**

**`posterior`** — Chaîne postérieure, en degrés, maximum saisissable 90
> Consigne au pratiquant : « Jambe tendue levée activement : estime l'angle atteint, en degrés. »
>
> Échelle visée : `luffy.posterior` (4 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **45** → échelon **2**
> - au moins **60** → échelon **3**
> - au moins **75** → échelon **4**

**`shoulder`** — Flexion épaule, en répétitions, maximum saisissable 10
> Consigne au pratiquant : « Wall flexion avec côtes contrôlées. »
>
> Échelle visée : `luffy.shoulder` (4 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **3** → échelon **2**
> - au moins **6** → échelon **3**
> - au moins **9** → échelon **4**

**`thoracic`** — Rotation thoracique, en répétitions, maximum saisissable 10
> Consigne au pratiquant : « Rotation active symétrique, sans compensation. »
>
> Échelle visée : `luffy.thoracic` (4 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **3** → échelon **2**
> - au moins **6** → échelon **3**
> - au moins **9** → échelon **4**


---

## Minato — `minato`

### Les échelles

**Accélération** · `minato.accel` — 4 échelons

1. **Éducatifs de course** *(Drills)* — Montées de genoux et talons-fesses, propres.
2. **Sprint 10 m** — Départ arrêté, récupération complète.
3. **Sprint 20 m** — Départ arrêté, récupération complète.
4. **Sprint 30 m** — Départ arrêté, récupération complète.

**Vitesse max** · `minato.maxv` — 4 échelons

1. **Lignes droites relâchées** *(Strides)* — Accélère progressivement, sans forcer.
2. **Sprint lancé** *(Fly 10)* — Prends de l'élan, puis 10 m à pleine vitesse.
3. **Sprint lancé** *(Fly 20)* — Prends de l'élan, puis 20 m à pleine vitesse.
4. **Sprint 60 m** — Départ arrêté, récupération complète.

**Réactivité** · `minato.cod` — 3 échelons

1. **Départ arrêté** — Position stable, puis départ franc.
2. **Départ arrêté** — Assis, à genoux, de dos : tu pars de là.
3. **Départ arrêté** *(Reactive start)* — Tu pars sur un signal extérieur.

**Support force** · `minato.support` — 3 échelons

1. **Renforcement de base** — Fentes, pont fessier, mollets.
2. **Renforcement sur une jambe** — Même travail, une jambe à la fois.
3. **Renforcement avancé** — Charges ou appuis plus exigeants.

### Les tests et leurs seuils actuels

**`10m`** — 10 m, en centièmes de seconde, maximum saisissable 1000
> Consigne au pratiquant : « Trois essais, récupération complète. En centièmes : 1,84 s s'écrit 184. »
>
> Échelle visée : `minato.accel` (4 échelons)
> Renseigne aussi : `minato.cod`, `minato.support`
>
> - au plus **200** → échelon **4**
> - au plus **230** → échelon **3**
> - au plus **270** → échelon **2**
> - au plus **10000** → échelon **1**

**`30m`** — 30 m, en centièmes de seconde, maximum saisissable 1500
> Consigne au pratiquant : « Deux à trois essais, garde le meilleur. En centièmes : 4,55 s s'écrit 455. »
>
> Échelle visée : `minato.accel` (4 échelons)
>
> - au plus **480** → échelon **4**
> - au plus **540** → échelon **3**
> - au plus **600** → échelon **2**
> - au plus **10000** → échelon **1**

**`60m`** — 60 m, en centièmes de seconde, maximum saisissable 2000
> Consigne au pratiquant : « Deux essais, et seulement si le terrain s'y prête. En centièmes : 8,40 s s'écrit 840. »
>
> Échelle visée : `minato.maxv` (4 échelons)
>
> - au plus **850** → échelon **4**
> - au plus **950** → échelon **3**
> - au plus **1100** → échelon **2**
> - au plus **10000** → échelon **1**


---

## Naruto — `naruto`

### Les échelles

**Endurance facile** · `naruto.easy` — 5 échelons

1. **Course et marche** *(Run/walk)* — Alterne course facile et marche.
2. **Course facile** — 20 à 30 minutes, tu dois pouvoir parler.
3. **Course facile** — 30 à 45 minutes, tu dois pouvoir parler.
4. **Course facile** — 45 à 60 minutes, tu dois pouvoir parler.
5. **Course facile** — 60 à 75 minutes, tu dois pouvoir parler.

**Sortie longue** · `naruto.long` — 5 échelons

1. **Sortie longue** — 40 à 55 minutes, allure confortable.
2. **Sortie longue** — 55 à 75 minutes, allure confortable.
3. **Sortie longue** — 75 à 95 minutes, allure confortable.
4. **Sortie longue** — 95 à 115 minutes, allure confortable.
5. **Sortie longue** — Des portions à l'allure du semi à l'intérieur de la sortie.

**Qualité aérobie** · `naruto.quality` — 5 échelons

1. **Lignes droites relâchées** *(Strides)* — Une vingtaine de secondes d'accélération progressive.
2. **Course avec accélérations libres** *(Fartlek)* — Alterne allures sans chronomètre.
3. **Course soutenue par blocs** *(Tempo)* — Des blocs à allure soutenue, avec récupération trottée.
4. **Course soutenue continue** *(Seuil)* — Allure que tu tiendrais environ une heure.
5. **Course à l'allure du semi** — L'allure que tu vises le jour du semi.

**Récupération** · `naruto.recovery` — 3 échelons

1. **Marche et course très facile** — Le but est de récupérer, pas de progresser.
2. **Course de récupération** — 20 à 30 minutes très faciles.
3. **Course de récupération** — 30 à 45 minutes très faciles.

**Renforcement coureur** · `naruto.strength` — 3 échelons

1. **Renforcement de base** — Fentes, pont fessier, gainage, mollets.
2. **Renforcement sur une jambe** — Même travail, une jambe à la fois.
3. **Renforcement avancé** — Charges ou appuis plus exigeants.

### Les tests et leurs seuils actuels

**`easyDistance`** — Ta distance facile, en mètres, maximum saisissable 42195
> Consigne au pratiquant : « Pas ton record : la distance que tu sais courir aujourd'hui à allure confortable, sans marcher. »
> Question posée : « Quelle distance peux-tu courir facilement aujourd'hui, sans marcher ? »
> Réponses : Je ne peux pas encore courir 2 km facilement (= 1000) / 2 km (= 2000) / 5 km (= 5000) / 7 km (= 7000) / 10 km ou plus (= 10000)
>
> Échelle visée : `naruto.easy` (5 échelons)
> Renseigne aussi : `naruto.recovery`
>
> - au moins **0** → échelon **1**
> - au moins **2000** → échelon **2**
> - au moins **5000** → échelon **3**
> - au moins **7000** → échelon **4**
> - au moins **10000** → échelon **5**

**`continuousRun`** — Course continue, en secondes, maximum saisissable 3600
> Consigne au pratiquant : « Cours à RPE 3–4 et arrête le test si tu ne peux plus parler en phrases complètes. »
>
> Échelle visée : `naruto.easy` (5 échelons)
> Renseigne aussi : `naruto.recovery`
>
> - au moins **0** → échelon **1**
> - au moins **900** → échelon **2**
> - au moins **1800** → échelon **3**
> - au moins **2700** → échelon **4**
> - au moins **3600** → échelon **5**

**`recent5k`** — 5 km récent, en secondes, maximum saisissable 3600
> Consigne au pratiquant : « Renseigne ton meilleur temps récent sur 5 km s’il date de moins de 8 semaines. »
>
> Échelle visée : `naruto.quality` (5 échelons)
> Renseigne aussi : `naruto.strength`
>
> - au plus **1500** → échelon **4**
> - au plus **1800** → échelon **3**
> - au plus **2100** → échelon **2**
> - au plus **10000** → échelon **1**

**`recent10k`** — 10 km récent, en secondes, maximum saisissable 7200
> Consigne au pratiquant : « Renseigne ton meilleur temps récent sur 10 km s’il reflète encore ton niveau actuel. »
>
> Échelle visée : `naruto.quality` (5 échelons)
>
> - au plus **3000** → échelon **5**
> - au plus **3600** → échelon **4**
> - au plus **4200** → échelon **3**
> - au plus **10000** → échelon **2**

**`longRun`** — Plus longue sortie récente, en mètres, maximum saisissable 21097
> Consigne au pratiquant : « Renseigne la distance de ta plus longue sortie des 30 derniers jours. »
>
> Échelle visée : `naruto.long` (5 échelons)
> Renseigne aussi : `naruto.long`
>
> - au moins **0** → échelon **1**
> - au moins **8000** → échelon **2**
> - au moins **12000** → échelon **3**
> - au moins **16000** → échelon **4**


---

## Rock Lee — `rocklee`

### Les échelles

**Landing** · `rocklee.landing` — 5 échelons

1. **Réception contrôlée** *(Snap down)* — Tu montes sur la pointe puis tu tombes en position de réception.
2. **Réception contrôlée** *(Drop to stick)* — Tu descends d'une marche et tu figes la réception.
3. **Réception contrôlée** — Même chose, sur un pied.
4. **Saut latéral** *(Lateral bound)* — Tu sautes sur le côté et tu tiens la réception.
5. **Réception contrôlée** *(Reactive landing)* — Tu reçois et tu repars immédiatement.

**Pogo** · `rocklee.pogo` — 5 échelons

1. **Petits sauts sur place** *(Ankle bounce)* — Tout petits rebonds, chevilles rigides.
2. **Petits sauts réactifs** *(Pogo)* — Rebonds bas, contact au sol le plus court possible.
3. **Petits sauts réactifs** *(Pogo)* — Rebonds plus hauts, contact toujours court.
4. **Petits sauts réactifs** *(Pogo)* — Le plus de rebonds possible en gardant le rythme.
5. **Petits sauts réactifs** — Un pied à la fois.

**Jump** · `rocklee.jump` — 5 échelons

1. **Saut vertical** *(CMJ)* — Flexion rapide puis saut le plus haut possible.
2. **Saut en longueur** *(Broad jump)* — Depuis l'arrêt, le plus loin possible, réception tenue.
3. **Saut en longueur** — Plusieurs sauts à la suite.
4. **Foulées bondissantes** *(Bounds)* — Grandes foulées sautées, alternées.
5. **Saut vertical** — Un seul saut, à fond, bien récupéré.

**Sprint** · `rocklee.sprint` — 5 échelons

1. **Montées de genoux techniques** *(A-march / A-skip)* — Genou haut, pied sous la hanche.
2. **Sprint 10 m** — Départ arrêté, récupération complète.
3. **Sprint 20 m** — Départ arrêté, récupération complète.
4. **Sprint 30 m** — Départ arrêté, récupération complète.
5. **Sprint 30 m** — À fond, récupération complète.

**COD** · `rocklee.cod` — 4 échelons

1. **Déplacements latéraux** *(Shuffle)* — Pas chassés, bassin bas.
2. **Demi-tour rapide** *(505)* — Tu cours, tu freines, tu repars dans l'autre sens.
3. **Appui et changement de direction** *(Lateral cut)* — Un appui franc pour repartir sur le côté.
4. **Changement de direction au signal** *(Reactive cut)* — Tu changes de direction sur un signal extérieur.

### Les tests et leurs seuils actuels

**`broad`** — Saut horizontal, en centimètres, maximum saisissable 400
> Consigne au pratiquant : « Trois essais depuis l'arrêt, garde le meilleur saut propre, mesuré en centimètres. »
>
> Échelle visée : `rocklee.jump` (5 échelons)
> Renseigne aussi : `rocklee.cod`
>
> - au moins **0** → échelon **1**
> - au moins **150** → échelon **2**
> - au moins **200** → échelon **3**
> - au moins **240** → échelon **4**

**`tenM`** — Accélération 10 m, en centièmes de seconde, maximum saisissable 1000
> Consigne au pratiquant : « Trois essais, récupération complète. Note ton meilleur temps en centièmes : 1,84 s s'écrit 184. »
>
> Échelle visée : `rocklee.sprint` (5 échelons)
>
> - au plus **190** → échelon **4**
> - au plus **210** → échelon **3**
> - au plus **240** → échelon **2**
> - au plus **10000** → échelon **1**

**`pogo`** — Pogos 10 s, en répétitions, maximum saisissable 50
> Consigne au pratiquant : « Compte seulement les contacts réactifs propres. »
>
> Échelle visée : `rocklee.pogo` (5 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **10** → échelon **2**
> - au moins **20** → échelon **3**
> - au moins **30** → échelon **4**

**`lateral`** — Lateral bound stick, en répétitions, maximum saisissable 10
> Consigne au pratiquant : « Cinq essais par côté, qualité avant distance. »
>
> Échelle visée : `rocklee.landing` (5 échelons)
>
> - au moins **0** → échelon **1**
> - au moins **3** → échelon **2**
> - au moins **6** → échelon **3**
> - au moins **9** → échelon **4**


---

## 7. Contrôle avant de rendre

- [ ] Chaque `level` existe bien dans l'échelle visée.
- [ ] Une table ne mélange pas `atLeast` et `atMost`.
- [ ] Les seuils se suivent sans trou ni chevauchement.
- [ ] Aucun point d'entrée ne place quelqu'un sur un échelon réservé au dernier jalon.
- [ ] Aucun point d'entrée ne laisse un pratiquant capable au niveau 1.
- [ ] Le JSON est valide et se suffit à lui-même.

**Commence par me dire quel programme tu traites, puis rends son JSON.**
