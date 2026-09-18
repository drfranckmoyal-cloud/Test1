# Shuō / 说 --- Master handoff for Claude Code

## Mission

Build the iOS V0 from the files in this package. **Do not redesign the
pedagogy.** Treat `00_SOURCE_OF_TRUTH_V2.json` as binding when
implementation choices are ambiguous.

## Product in one sentence

Shuō is an oral-first Mandarin tutor whose pedagogical spine is HSK 3.0
Level 1, with strict tone/pronunciation work, adaptive spaced review,
guided-to-free conversation, and a persistent learner model.

## Non-negotiables

-   1--3 new words/expressions maximum per normal session.
-   HSK official scope is separated from Shuō-authored examples and
    teaching scripts.
-   Hanzi are shown from the beginning, but reading is not a blocking
    criterion for the oral-first pass.
-   The learner finishes an attempt before correction, except for
    prolonged blocking.
-   `aide` = graded help; `réponse` = immediate solution; `arrête-toi` =
    return to guided mode/pause.
-   A badly pronounced word cannot become green merely because the
    ASR/LLM understood it.
-   Review draws from the whole history and can upgrade or downgrade
    mastery.
-   One isolated failure never downgrades a green item.
-   Hands-free and push-to-talk are switchable during the session.
-   Learner speech interrupts tutor audio immediately.
-   The active model name is visible; dev mode logs latency, tokens and
    cost.
-   Target cost is approximately €1.25/hour, as a soft optimization
    target, not a hard pedagogical cap.

## Implementation order

1.  Data layer + learner state.
2.  Session orchestrator.
3.  One vertical slice: P01--P04 + S001--S012 + due reviews.
4.  Voice loop and barge-in.
5.  Word-card UI.
6.  Review mode.
7.  Developer telemetry/model routing.
8.  Remaining curriculum.
9.  Tutor/avatar polish.

## Definition of V0 success

A learner can complete several sessions, close the app, return later,
recover the exact progression, see fragile content reappear, receive
strict-but-bounded pronunciation correction, switch voice interaction
mode, and hold a short level-appropriate conversation using learned
content.

## Important copyright boundary

The package uses the official HSK syllabus as scope and public metadata
from the officially authorized 2026 textbook for alignment. It does
**not** reproduce proprietary textbook dialogues, lesson text or
exercises. All Shuō examples/dialogues are original.
