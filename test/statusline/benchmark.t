Profile status line execution time:

  $ . "$TESTDIR"/helpers.sh

Set up a realistic directory tree for path shortening:

  $ mkdir -p "$CRAMTMP/home/Workspace/pano-ops/pano-ec/.git"
  $ mkdir -p "$CRAMTMP/home/Workspace/pano-platform"
  $ mkdir -p "$CRAMTMP/home/Workspace/personal"
  $ cd "$CRAMTMP/home/Workspace/pano-ops/pano-ec"
  $ git init -q

Build realistic JSON with all fields populated:

  $ NOW=$(date +%s)
  $ RESET_5H=$(( NOW + 10800 ))
  $ RESET_7D=$(( NOW + 432000 ))
  $ CWD="$CRAMTMP/home/Workspace/pano-ops/pano-ec"
  $ JSON=$(HOME="$CRAMTMP/home" make_json '.cwd = "'"$CWD"'" | .workspace.project_dir = "'"$CWD"'" | .context_window.used_percentage = 45 | .rate_limits.five_hour.used_percentage = 62 | .rate_limits.five_hour.resets_at = '"$RESET_5H"' | .rate_limits.seven_day.used_percentage = 35 | .rate_limits.seven_day.resets_at = '"$RESET_7D"'')

Warm up:

  $ echo "$JSON" | HOME="$CRAMTMP/home" COLUMNS=120 bash "$STATUSLINE" > /dev/null

Measure 5 runs and report average:

  $ total=0
  > for i in 1 2 3 4 5; do
  >   start=$(python3 -c 'import time; print(int(time.time()*1000))')
  >   echo "$JSON" | HOME="$CRAMTMP/home" COLUMNS=120 bash "$STATUSLINE" > /dev/null
  >   end=$(python3 -c 'import time; print(int(time.time()*1000))')
  >   elapsed=$(( end - start ))
  >   total=$(( total + elapsed ))
  > done
  > avg=$(( total / 5 ))
  > echo "Average: ${avg}ms"
  > if [ "$avg" -le 150 ]; then
  >   echo "PASS: under 150ms target"
  > else
  >   echo "WARN: ${avg}ms exceeds 150ms target - consider adding path cache"
  > fi
  Average: *ms (glob)
  PASS: under 150ms target (glob)
