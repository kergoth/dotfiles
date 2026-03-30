Test rate limit pace calculation and display:

  $ . "$TESTDIR"/helpers.sh && source_functions

Format time-to-exhaustion:

  $ format_time_remaining 900
  ~15m (no-eol)
  $ format_time_remaining 4320
  ~1.2h (no-eol)
  $ format_time_remaining 86400
  ~1.0d (no-eol)
  $ format_time_remaining 155520
  ~1.8d (no-eol)
  $ format_time_remaining 60
  ~1m (no-eol)
  $ format_time_remaining 7200
  ~2.0h (no-eol)

Rate limit visibility — below threshold returns empty:

  $ format_rate_limit "5h" 30 0 18000

Above threshold, on-track (won't exhaust before reset):

  $ format_rate_limit "5h" 55 12600 18000
  5h \xe2\x9c\x93 55% (no-eol) (esc)

Above threshold, over-pace (will exhaust before reset):

  $ format_rate_limit "5h" 62 7200 18000
  5h \xe2\x9a\xa0 62% ~1.2h (no-eol) (esc)

Critical (>= 80%), over-pace:

  $ format_rate_limit "5h" 89 14400 18000
  5h \xe2\x9a\xa0 89% ~* (no-eol) (esc) (glob)

7-day window on-track (10% used in 1 day of 7 = pace of 70% by end):

  $ format_rate_limit "7d" 52 345600 604800
  7d \xe2\x9c\x93 52% (no-eol) (esc)

Severity classification:

  $ rate_limit_severity 30 false
  hidden
  $ rate_limit_severity 55 false
  on_track
  $ rate_limit_severity 62 true
  over_pace
  $ rate_limit_severity 89 true
  critical

Smart degradation — keep worse state:

  $ worse_rate_limit "critical" "on_track"
  first
  $ worse_rate_limit "on_track" "over_pace"
  second
  $ worse_rate_limit "hidden" "on_track"
  second
  $ worse_rate_limit "on_track" "on_track"
  first
