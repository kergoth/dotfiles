import sys

formatted_args = []

UNSAFE_CHARACTERS = [" ", "!", "\"", "#", "$", "&", "'", "(", ")", "*", ",", ";", "<", ">", "?", "[", "\\", "]", "^", "`", "{", "|", "}", ":", "~", "/"]


def find_unsafe(arg):
    for unsafe in UNSAFE_CHARACTERS:
        if unsafe in arg:
            return True

    return False


for arg in sys.argv[1:]:
    if find_unsafe(arg):
        formatted_args.append('"%s"' % arg)
    else:
        formatted_args.append(arg)

print("$ " + " ".join(formatted_args))
