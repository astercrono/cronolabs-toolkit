#!/usr/bin/env bash

# clt provision list # list all possible targets
#
# clt provision <target>
#
# Targets:
#
# - local/cronbook
# - local/cronbox
# - lab/mc
# - lab/proxy
# - lab/db
# - lab/wiki
# - lab/smg
# - lab/smuk

target="$1"

case "$target" in
"local/cronbook") ;;
"local/cronbox") ;;
"lab/mc") ;;
"lab/proxy") ;;
"lab/db") ;;
"lab/wiki") ;;
"lab/smg") ;;
"lab/smuk") ;;
esac
