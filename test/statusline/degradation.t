Test width-based degradation tiers:

  $ . "$TESTDIR"/helpers.sh && source_functions

Measure visible width of a string:

  $ visible_width "hello"
  5

Tier 0 — all segments fit (width=68, cols=70):

  $ select_degradation_tier 70 "Opus" "W/p-o/pano-ec" "main" "5h x 62% ~1.2h" "7d x 52%" "ctx 45%"
  0

Tier 1 — drop second rate limit (width=68 > 65, but 58 <= 65):

  $ select_degradation_tier 65 "Opus" "W/p-o/pano-ec" "main" "5h x 62% ~1.2h" "7d x 52%" "ctx 45%"
  1

Tier 2 — drop path (width=58 > 50, but 43 <= 50):

  $ select_degradation_tier 50 "Opus" "W/p-o/pano-ec" "main" "5h x 62% ~1.2h" "" "ctx 45%"
  2

Tier 3 — drop branch (width=43 > 40, but 37 <= 40):

  $ select_degradation_tier 40 "Opus" "" "main" "5h x 62% ~1.2h" "" "ctx 45%"
  3

Tier 4 — minimum (model + context only):

  $ select_degradation_tier 20 "Opus" "" "" "" "" "ctx 45%"
  4

No rate limits shown — tier 0 at moderate width:

  $ select_degradation_tier 50 "Opus" "W/p-o/pano-ec" "main" "" "" "ctx 45%"
  0
