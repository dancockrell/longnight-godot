# The Long Night — Godot redesign

Status: **design under review.** Nothing here is settled lore. Written
27 Aug 2026 by the longnight session.

## What is verified, what is proposed, what is pending

Per CLAUDE.md rule 19, this document separates the three and does not let
them blur. Where this document and `world-aflame-godot/docs/LORE-BIBLE.md`
disagree, **the bible wins** — it is the only authority for this universe
and this file is a proposal to it.

- **Verified** = I ran the command or read the file. Check it yourself with
  the command given.
- **Proposed** = my design decision, mine to defend, not lore.
- **PENDING RULING** = I have asked and have not been told. Do not build
  story content on these.

---

## 1. What exists today (verified)

Read the source: `git clone https://github.com/dancockrell/longnight`.

    cd longnight && wc -l js/*.js     # 9,554 lines, 01_core .. 10_modern

Autumn 1888, London. A party of writers walks a fogged tile-map city and
investigates the Whitechapel murders. The murders are real and unsolved and
**there is no killer to fight** — the source says so in a comment above the
scene table in `js/08_story.js`. What the trail turns up is a city looking
hard in one direction and therefore nowhere else.

The scenes are the best writing in the game and all five are documentary:

| Scene | What it is |
|---|---|
| Goulston Street | Chalk above a piece of apron, washed off before it could be photographed, on the Commissioner's own order, because he feared a riot. Abberline argued and lost. |
| Flower and Dean Street | Fourpence buys a bed. Twopence buys a rope stretched across the room that you lean on until morning, when they cut it down. |
| The mortuary shed | Whitechapel has no mortuary. Two paupers wash the body before the doctor arrives, because nobody told them not to, because there is no procedure. |
| Clerkenwell | Unconsecrated ground. More names than stakes. The same class of woman the papers are naming in Whitechapel, only here there is no headline. |
| The parlour | A seance. Curtains drawn at four in the afternoon. |

The boss is Count Dracula at Carfax, and his argument is the game's thesis:

> "Four hundred columns this autumn about a man who kills women in
> Whitechapel, and not one line about a ship that came into Whitby with a
> dead crew. I did not have to hide. You were all looking somewhere else,
> and you paid a penny for the privilege."

Two endings, chosen by typing DAWN or NIGHT. The night ending is not a fail
state; it is the one where you leave the shutters closed, circulation rises,
and the boxes go out by cart to Piccadilly and Bermondsey. It closes by
asking the player why that ending was easier to arrange than the other one.

**Systems worth carrying over.** Verified by reading `js/07_combat.js` and
`js/06_world.js`:

- Threat/aggro with per-role rates (tank 2.4, dps 1.0, healer 0.55)
- Three stances trading damage out against damage in
- Bond combos between specific character pairs
- DragonRealms-style skill training: use a skill to train it, a 21-step
  mind-state shows how full the learning pool is, ranks drain in over time
- Five skillsets, five gear slots (pen, coat, lamp, volume, charm)
- A day/night clock with deep-night and near-midnight bands
- Crowd simulation with period street cries
- A runtime-synthesised orchestra with convolution reverb and a master
  limiter, so the game ships with no audio files at all

## 2. What is actually wrong with it

Not the argument. The argument is excellent and it is already Project 42's
argument, which is the finding that makes this port worth doing at all.
The execution is where it falls short of a modern RPG.

1. **Twenty-three characters across three roles is a select screen, not a
   cast.** Nobody has an arc. Nobody disagrees with anybody. Verified:
   `grep -o "role:'[a-z]*'" js/04_cast.js | sort | uniq -c` gives 6 tank,
   11 dps, 6 healer. Dan has asked for five, and five is right.

2. **The investigation is a checklist.** Five scenes, walk to each, read
   five lines, a counter goes up. `G.clues>=3` unlocks one dialogue branch
   and a party heal. That is the entire consequence of the detective game.

3. **Investigation and combat are two games bolted together.** You walk the
   fog, read a documentary scene about a mortuary shed, and then fight a
   wolf. The wolf has nothing to do with the shed.

4. **The ending is a typed word.** Two branches, no build-up, and no way
   for the player to have earned either one.

5. **Reading is the interface.** It is a text log in a canvas. That was a
   constraint of writing an engine by hand, not a choice.

## 3. The core idea of the redesign

**Attention is the resource, and it is the same resource in both halves of
the game.**

The thesis is already about attention: what a city looks at, and what it
therefore does not. Right now that is a theme the writing states. It should
be a mechanic the player operates, and it should be the thing that connects
the investigation to the fighting, which currently have nothing to do with
each other.

- The city has more happening in it than any party can look at. A night
  spent in Whitechapel is a night not spent in Purfleet.
- What you look at gets printed. What gets printed sells. Circulation is
  not a score, it is a **cost**: the thing you did not look at advances
  while the presses run.
- In combat, threat already is attention, and the engine already tracks it.
  Extend it outward: a loud, showy fight in a public street buys column
  inches and therefore buys the enemy cover somewhere else. The quiet win
  nobody prints is the expensive one and the right one.
- **Dracula is not a health bar.** He is the scoreboard. His advantage is a
  stat that rises when attention is spent elsewhere, which makes the final
  encounter a reckoning with how the player spent five nights rather than a
  damage race. The 840 HP sponge in `js/08_story.js` goes.

That one change fixes problems 2, 3 and 4 together, and it is the version
of this game that could not be made about anything else.

## 4. The cast: five, and they disagree

**Proposed.** The party stops being real authors. This began as the P42
session's suggestion — recruit *works* rather than people — and I have
pushed it a step further.

Idea space is where stories live (bible section 5). So what reaches into
1888 London is not a person. It is a **form** — a way of telling — and the
five party members are invented Londoners who have been reached into and
now carry one.

Five forms, five theories of what writing is for, and they are not
compatible with each other. The party's internal argument is the real
conflict of the game, and every attention spend makes one of them right and
another one wrong.

| | Form | The argument it makes | Mechanically |
|---|---|---|---|
| The Correspondent | The dispatch | Make them look. Naming a thing is the whole job. | Forces attention. Aggro, control, and the ability to put a target on the front page. |
| The Alienist | The detective story | There is a solution and method will find it. | Deduction and analysis. The horror is that the form *demands* a solution and the real case has none. |
| The Penny Blood | The sensation serial | Give them what they will actually buy. | Enormous damage that **feeds the enemy**, because sensation is what Dracula eats. The strongest and most dangerous member. |
| The Witness | Testimony | I was there. This happened. | Almost no damage. The only one who can make a fact *stick* so it cannot be washed off a wall. |
| The Proprietor | Circulation | Somebody has to pay for the paper. | Every ability helps the party and costs the city. |

Why this shape:

- **It is clean against section 2 rule 9 by construction.** No real person
  is a playable piece.
- **The Penny Blood is the thesis as a mechanic.** A party member whose
  damage output actively strengthens the thing you are fighting is the
  four-hundred-columns argument in a form the player has to operate rather
  than read.
- **The Proprietor is the bill.** Bible section 2 rule 6 says the side the
  player is invited to sympathise with does not get a clean war, and
  section 3 takes complicity-as-texture from *The Man in the High Castle*.
  A sympathetic, useful party member whose every use costs somebody else is
  how that lands in a five-person RPG.
- **It explains Holmes and Abberline rather than excusing them.** Holmes is
  a fictional character; Abberline was a real detective on the real case.
  A room containing both is *itself* an idea-space event. The P42 session's
  point, and it is a good one.

## 5. Setting — PENDING RULING

**Proposed by the P42 session, adopted by me, awaiting the lore thread.**

Long Night stays in 1888 and becomes **the first contact with idea space**.

Bible section 5 says the intelligence reached in, that the Imperial
programme's belief it struck a bargain is unsupported by the record, and
that the treaty was written afterward so there would be something to file.
If that is true in 1944, then something reached in earlier, before there
was a state to file anything — and nobody wrote it down at all.

That is Long Night, and the fact that there is no record **is** the theme.

Three reasons this beats re-setting the game in the P42 period:

- It keeps a Victorian entry sixteen years clear of the 1904 extermination
  order. The bible's genocide spine starts in 1904; a literary-cast party
  RPG set inside it would be a much worse idea than the one it solves.
- Idea space belongs to Hyakki Yako, not to Germany, so this can never
  drift into German occultism — the rule the bible flags as most likely to
  be broken by accident.
- It costs nothing. The existing 9,554 lines stay usable as source material
  rather than being thrown out for a fourth reskin of a setting that
  already has three factions.

**The objection to it, raised by a red-team session and it is a real one.**
1888 is not a free year. It is the *first line* of section 4, the
divergence timeline, and it is tagged `(real)`:

> - **1888** — Wilhelm II takes the throne. *(real)*

The divergence itself is **1918**, four entries later, when the Empire
fails to fall. So putting a supernatural first contact in 1888 inserts
fiction into a stretch the bible currently marks as unaltered history, at a
date already claimed for a specific anchor.

Second half of the same objection: idea space currently belongs to Hyakki
Yako (line 333). "First, unrecorded contact" is therefore a claim about
**Hyakki Yako's origin story**, not a free invention — it establishes that
the thing touched London roughly fifty years before it touched the Empire.
And section 2 rule 4 carves the supernatural to Hyakki Yako specifically,
so a British supernatural setting is a faction-shaped hole in that scheme
even though it is not German.

My read: none of that is fatal. `(real)` tags which *listed events* are
historical, not that the year is sealed, and a contact nobody recorded is
by construction invisible to the historical record the tag is about. But
it is a change to the spine of the timeline and it is the bible owner's to
approve, not mine to assume.

**Ownership is currently unresolvable from inside a session.** The bible's
header says "Owner: lore thread" and names no contact route. Every commit
in that repo is authored `Dan Cockrell <...noreply...>` because CLAUDE.md
rule 10 requires it, so git cannot distinguish sessions. I asked four
peers; all four said not me, and none could name the owner from evidence.
Worth a line in the bible's header naming a route, so the next session does
not pay this again.

## 6. Open rulings — do not build on these

1. **The five victims' names.** The epilogue names five real murdered women
   and the night ending asks the player why that was the easier ending to
   arrange.

   The governing rule is **section 2 rule 9**, not section 9 — section 9 is
   the iteration log, and I had this wrong until a red-team session caught
   it. Verify with `grep -n "^## " docs/LORE-BIBLE.md`. Verbatim, at
   line 128:

   > 9. **Real victims' names are not used, ever.** Real perpetrators and
   > real events may be cited factually in out-of-fiction material — this
   > document, designer notes, a codex — where the whole point is
   > historical grounding. In-fiction, the perpetrators are our invention.

   **Two red-team sessions read this clause differently, which is itself
   the reason it needs Dan.** One holds that the carve-out reaches a codex
   and all five could be named there. The other holds that the carve-out is
   attached to *perpetrators and events* and never mentions victims.

   Reading it myself: the second is right. Sentence one is unqualified
   about victims. Sentence two carves out perpetrators and events. Sentence
   three is about perpetrators again. Victims appear once, in the absolute
   sentence. On the text as written the answer is no, in-fiction **and** in
   a codex.

   Section 2.2 ("victims are never units") does not apply — it is scoped to
   victims of a real *genocide*, and Whitechapel is not that. So 2.9 is the
   whole of the problem.

   Against the text: this naming is doing the opposite of exploitation. It
   is Hallie Rubenhold's argument in *The Five*, refusing to let five women
   stay "the Ripper's victims" and nothing else. The rule was written to
   stop real dead people being used as content, and a memorial is the one
   use that is not that.

   **This is Dan's call.** Not mine, not the bible owner's, and not two
   agents agreeing with each other. Changing it means amending the
   constitution, which is his to amend.

2. **Kafka is out, and I am not treating this as open.** His three sisters
   — Elli, Valli and Ottla — were murdered in the Holocaust; Ottla died at
   Auschwitz after volunteering to accompany a transport of children out of
   Theresienstadt. A playable Kafka in a universe whose thesis is "remove
   Hitler and it still happens" is one step from rule 2 and the step is his
   sisters. Flagged by the P42 session. Resolving it by simply not
   mentioning the sisters would be worse than the inclusion.

3. **Recency and adjacency, if any real person is ever used.** Achebe
   (d. 2013), Morrison (d. 2019) and Marquez (d. 2014) are within living
   memory with surviving families, and Achebe additionally sits on the
   colonial axis the bible's Herero and Nama spine runs along. Section 4's
   proposal removes this question rather than answering it, which is the
   better outcome.

## 7. Not yet true

An explicit list, per CLAUDE.md rule 9, so nothing here reads as shipped:

- **No Godot code is written.** The directory scaffold exists and Godot
  4.7.2 is verified present. That is all.
- **The attention system in section 3 has never been played.** It is a
  design, not a measurement. The first thing to build is a headless harness
  that runs it at volume, before any art or story goes near it.
- **No story text has been written** and none will be until ruling 1 lands.
- **The five characters have names-by-function, not names.**
