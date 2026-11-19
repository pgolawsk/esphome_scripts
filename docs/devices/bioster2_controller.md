# BIOSTER 2 — sewage treatment plant controller (Elektro-Miz)

Working notes distilled from the manufacturer's manual so the PDF does not have to be re-read.
Source: *Instrukcja obsługi regulatora do przydomowych ekologicznych oczyszczalni ścieków BIOSTER 2, ver. 04/2025*, ELEKTRO-MIZ Pleszew (8 pp; the copy Pawelo supplied was archived by Larry in the vault).
Page refs: "p.N" = PDF page, printed number in brackets.

**Scope warning.** The manual covers the *user-facing behaviour* of BIOSTER 2. It has **no RS485/Modbus section**, no register map and no parameter units or defaults. Pawelo's unit is a Haba "MULTI BIO" (Elektro-Miz MultiBio 2000 family) sniffed by `esp32-32` (`set_haba_rs485`). Same parameter family, **different generation** (inferred). Items below are labelled **[M]** = stated in the manual, **[S]** = confirmed on the sniffer (Loki, 2026-11-11 → 2026-11-19), **[I]** = inferred, **[G]** = guess.

## 1. Hardware (p.3 [2], p.4 [3], p.7 [6])
| Item | Value |
|---|---|
| Supply | 230 V AC ±10 %, 50 Hz; idle draw 1.5 W [M] |
| Outputs | blower D1, main pump P1, signal lamp 230 V; max 100 W each [M] |
| Input | max-level float ("pływak poziomu maksymalnego") [M] |
| Terminals | 10: blower (L N PE), pump P1 (L N PE), lamp (L N), float. **No RS485 terminals** [M] |
| Fuse | 3.15 A, front socket [M] |
| Panel | 2-digit display "TRYB PRACY / FAZA PRACY"; LEDs D1, P1, (blank), POZIOM MAX, ALARM MAX, ON; keys ▲ ▼ ↵; mains switch [M] |

## 2. Operation cycle (p.6 [5])
1. Normal operation: blower runs in a schedule (aeration `n` / denitrification `d`).
2. **Float rises** (max level): blower stops, **sedimentation `S`** for **t1**.
3. After t1: **pump P1 runs for t2** (phase `o`, pumping out treated water).
4. After t2: back to normal operation [M, verbatim idea: "po tym czasie następuje powrót do normalnej pracy"].
5. **Overflow alarm `A`** if the float is *still up* after t1 + t2: all other devices are switched off, alarm lamp; ends when the float falls [M].

Alarm causes listed [M]: pump failure; float failure (mechanically stuck — tapping the float can help); t2 set too short.
Trigger of `S`/`o` is the **float, not a timer** [M]. On the rig `S`→`o` = 39m34s and `o` = 20m06s (t1 = 40, t2 = 20) [S].

## 3. Display codes (p.4 [3], p.6 [5])
Display = **mode** symbol + **phase** symbol.
| Mode (TRYB) | Phase (FAZA) |
|---|---|
| `n` normal · `u` vacation ("urlopowy") | `n` aeration (natlenianie) · `d` denitrification · `S` sedimentation · `o` pumping (odpompowanie) · `A` alarm |
Messages: `nn nd nS nO nA` and `un ud uS uO uA`. `n` is both the mode letter and a phase letter.

## 4. Menus (p.4 [3])
| Menu | Entry | Use |
|---|---|---|
| Manual ("ręczne") | hold `↵` ~5 s (text also says ~3 s) | `↵` moves between screens, `▲▼` switch each connected device on/off |
| Service ("serwisowe") | hold `▽` ~5 s | `↵` moves between parameters, `▲▼` change values; changes the plant's operating modes |

## 5. Service parameters (p.5 [4])
The manual lists the symbols only (no units/defaults).
| Symbol | Meaning (manual wording) | Likely unit |
|---|---|---|
| t1 | sedymentacja | min [I] |
| t2 | czas pracy pompy | min [I] |
| t3 | czas pracy pompy w nocy | min [I] |
| Ur | dni do urlopu | days [I] |
| iN / oN | czas pracy / postoju dmuchawy | min [I] |
| iP / oP | czas pracy / postoju dmuchawy w głównym postoju | min [I] |
| iU / oU | czas pracy / postoju dmuchawy w urlopie | min [I] |
| G1 / G2 | godzina nocnej sedymentacji (godzina / minuty) | h / min [I] |

## 6. Vacation mode `u`
- Own blower times iU/oU. Rule for entering/leaving is **not in the manual** ("Ur = dni do urlopu" only).
- On the rig: `u` began 11-15 02:00:18 after ≥ 3.7 days with no float event, at a blower-cycle boundary; ended at the end of the next `o` [S/I]. Days threshold likely ≈ 4 [G].
- Vacation blower cycle seen: 5 min on / 15 min off [S].

## 7. Haba rig: what the sniffer sees (not from the manual)
FC16 block 2000–2009 every ~61.5 s from slave 06: `2000`=13103 (const), `2001` state bits, `2002`=28 (const), `2003` blower-on minutes (+1/min in `n`), `2005` pump minutes (+20 per `o`).
| 2001 bits | Meaning |
|---|---|
| 7–6 | phase: 01 `n`, 10 `d`, 11 `S`, 00 `o` [S] |
| 5 | `u` vacation mode [S] |
| 8 | pumping phase [I] |
| 0 | blower D1 on [I] |
| 1 | pump P1 on [I] |
| 3 | float "level OK" (0 in `S` and first ~3 min of `o`) [I] |
Values: 73 `nn`, 136 `nd`, 192 `nS`, 258/266 `nO`, 105 `un`, 168 `ud`, 224 `uS`, 290/298 `uO`. Alarm code never seen.

Settings blocks (FC16, decoded words): `@1–9` = 40, 20, 5, 90, 30, 1, 5, 0x031E, 1 · `@14–15` = 5, 15.
| Word | Value | Parameter | Label |
|---|---|---|---|
| @1 | 40 | t1 | [S] |
| @2 | 20 | t2 | [S] |
| @3 | 5 | t3 | [G] |
| @4 | 90 | iN (blower on 90 min) | value [S], name [I] |
| @5 | 30 | oN (blower off 30 min) | value [S], name [I] |
| @6 | 1 | iP (1 min on in the 30-min stop) | value [S], name [I] |
| @7 | 5 | oP (5 min off in the 30-min stop) | value [S], name [I] |
| @8 | 0x031E | G1:G2 = 03:30? | [G], doubtful: no `S` at 03:30 on any night |
| @9 | 1 | unknown | [G] |
| @14 / @15 | 5 / 15 | iU / oU | [S] |

Observed rhythm in normal mode: 90 min `n`, then a 30 min block of 5 × (5 min `d` + 1 min `n`), repeat every 2 h (+~12 s drift). The cycle **restarts 90 min after every `o` end** [S]. Details and evidence: `inbox/archive/*LARRY_DONE_haba_check_1118_manual.md` (ephemeral) and the Larry vault notes.

## 8. Practical notes
- For a Haba panel photo: ask Pawelo for the display values of t1/t2/iN/oN/Ur/G1/G2 to settle `@3`, `@8`, `@9` and Ur.
- Float-driven `S`: expect `S` after a given *inflow volume* since the last `o` (rig: ~410–423 L home metering, one data point) [S/G].
- Do not rely on this manual for Modbus work; use the sniffer captures.
