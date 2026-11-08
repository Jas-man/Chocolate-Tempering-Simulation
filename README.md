# Engineer the Perfect Chocolate — tempering simulation

A MATLAB simulation for a chemical-engineering student competition. Your team
programs a **heating / cooling jacket** around a stirred vessel of melted
chocolate. You choose how hot or cold the jacket is, for how long, and how fast
you stir. The simulation then predicts the chocolate temperature, how many
crystals form, how many survive reheating, and awards a **quality score out of
100** — while the clock and the electricity meter are running.

> **This is a teaching model.** It uses simplified, round-number assumptions so
> that the *trade-offs* are realistic. It does **not** predict the quality of
> real chocolate, and its numbers must not be used for real production.

---

## 1. Quick start (no MATLAB programming needed)

Open MATLAB (R2019a or newer for the interface), set the *Current Folder* to this
folder, and use **either** route:

**Route A – the interface**

```matlab
TemperingLab
```

Type your team name, edit the numbers in the table, press **Run simulation**,
read the graphs and the score breakdown, repeat. When you are happy press
**Save submission** and hand in the file(s) created in the `submissions` folder.
The faint dashed line on the graphs is your *previous* run, so you can see the
effect of each change.

**Route B – edit a text file**

1. Open `team_inputs.m`, change the numbers (keep the brackets), save.
2. Run `run_team_inputs` — report and graphs appear.
3. Run `run_team_inputs(true)` to also save a submission file.

---

## 2. What you control

The batch starts as **fully melted chocolate at 45 °C** and runs through up to
five stages in order. Each stage has three numbers:

| Setting | Meaning | Allowed |
|---|---|---|
| Jacket set-point (°C) | Temperature the jacket is told to hold. The *chocolate* lags behind it. | 10 – 50 |
| Duration (min) | Length of the stage; `0` skips it. | 0 – 60 |
| Stirrer (rpm) | Speeds up heat transfer and helps crystals nucleate, but adds heat and costs energy (∝ rpm³). | 0 – 150 |

Typical use: stage 1 cool down, stage 2 crystal-forming hold, stage 3 reheat,
stage 4 working-temperature hold, stage 5 spare. Values outside the ranges are
clipped and you are told.

## 3. Constraints

| Constraint | Limit |
|---|---|
| Total processing time (sum of durations) | **35 min** |
| Total electrical energy (heater + chiller + stirrer) | **40 Wh** |

A design that breaks either limit is **invalid**: it is still simulated so you can
learn from it, but it ranks below every valid design.

## 4. The quality score (0–100)

| Group | Item | Points | What earns the points |
|---|---|---|---|
| **A. Temperature-profile compliance (30)** | Time in seeding window | 10 | Chocolate spends ≥ 6 min between 26 and 28 °C |
| | Final working temperature | 12 | Mean of last 3 min inside 31–32 °C |
| | No excursions | 8 | Little time outside 25–34 °C once cooling has begun |

| **B. Crystallisation opportunity (35)** | Stable-crystal amount | 25 | Peak Form V fraction reaches 0.45 |
| | Stable-crystal selectivity | 10 | Form V is the dominant crystal at its peak |

| **C. Crystal retention (35)** | Retention | 15 | ≥ 90 % of the Form V peak survives reheating |
| | Final crystal level | 10 | Final Form V between 0.30 and 0.50 (not under- or over-tempered) |
| | Unstable crystals purged | 10 | Unstable crystals melted out by the end |

## 5. How teams are ranked

1. Valid designs rank above invalid ones.
2. **Primary: quality score.** Scores are grouped in bands of 2 points; a higher band always wins.
3. **Secondary: inside a band**, the higher *efficiency index*
   `0.5·(1 − time/35) + 0.5·(1 − energy/40)` wins — faster and cheaper to run.
4. Raw quality breaks any remaining tie. Only your team's best submission counts.

Organisers re-run every submitted *design* themselves, so only the inputs you
hand in matter, not the score on your screen.

## 6. What the model does (and assumes)

**Process.** A well-mixed vessel of 2 kg chocolate in a jacket. The jacket fluid
is heated/cooled by a power-limited heater (500 W) and chiller (300 W,
COP = 3) under proportional control towards your set-point.

```
M·cp·dT/dt  = UA(N)·(Tj − T) + P_shaft(N) + Q_latent
Cj·dTj/dt   = Q_util − UA(N)·(Tj − T) − UA_amb·(Tj − T_amb)
UA(N)       = UA_min + (UA_ref − UA_min)·(N/N_ref)^0.67
P_shaft(N)  = P_ref·(N/N_ref)^3
```

**Crystals.** Two populations, each a fraction (0–1) of a fixed capacity:
`xV` = stable **Form V** crystals (wanted, melt at 33.5 °C) and `xU` =
**unstable** crystals (melt at 30 °C, form faster, unwanted). For each:

```
driving force  s    = max(0, (Tm − T)/10 K)
mobility            = 1/(1 + exp(−(T − 17)/2))          (sluggish when cold)
growth              = k · s^1.5 · mobility · (x + nuc·(1 + N/N_ref)) · (1 − xV − xU)
melting             = k_melt · max(0, T − Tm) · x
dx/dt               = growth − melting
```

Growth is *autocatalytic*: existing crystals seed more crystals. Stirring boosts
nucleation. Crystallising releases a little latent heat, melting absorbs it.

**Energy.** Heater electricity + chiller heat removed ÷ COP + stirrer shaft
power ÷ 0.6. Everything is integrated with a fixed 1 s Runge–Kutta step.

**Simplifications (deliberate).**

- Lumped, perfectly mixed chocolate; no temperature gradients, no viscosity-dependent heat transfer.
- Two crystal "species" instead of the six real cocoa-butter polymorphs; no polymorphic transformation between them, no fat bloom, particle size or flavour effects.
- Round-number kinetic and equipment parameters chosen for teaching, not measured.
- Start-up melting energy before t = 0 is not counted. Chocolate type is not modelled.
- The score is a game metric built from the simulated curves, not a measure of real quality.

All constants are in `tempering_config.m`, each with units and a comment.

## 7. Things to think about

- Why does the chocolate not simply follow the jacket? What sets the lag, and how does stirring change it?
- Cooling too hard makes unstable crystals fast. How does the reheating stage deal with them — and how far can you reheat before you melt what you wanted?
- Stirring helps nucleation and heat transfer. What does it cost in energy and in heat?
- Which is cheaper: a long gentle profile or a short aggressive one? Where do you hit a limit first?

## 8. Files

| File | Purpose |
|---|---|
| `TemperingLab.m` | Interface (run this) |
| `team_inputs.m`, `run_team_inputs.m` | Edit-the-numbers route |
| `tempering_config.m` | Every constant, limit and scoring parameter (organisers) |
| `simulate_tempering.m`, `score_tempering.m`, `run_design.m` | Model, scoring, one-call wrapper |
| `plot_tempering.m`, `report_text.m` | Graphs and text report |
| `validate_design.m`, `default_design.m`, `save_submission.m` | Input checking, starter design, submission files |
| `organiser/` | Ranking script, self-test and organiser guide — **keep away from participants** |
