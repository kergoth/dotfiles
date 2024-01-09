# Blinking block cursor style by default
# 30: blinking block
# 31: blinking block also
# 32: steady block
# 3: blinking underline
# 34: steady underline
# 35: blinking bar
# 36: steady bar
export CURSORCODE="\x1b[\x35 q"
printf "$CURSORCODE"
