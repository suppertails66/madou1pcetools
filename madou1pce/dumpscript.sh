set -o errexit

mkdir -p script/orig

# originally, this dumped directly to the "script" folder.
# then i accidentally ran this shell script and overwrote
# the translated, edited script with the raw dump.
# (good thing i keep backups!)
# so, for the sake of not repeating the experience,
# let's not target that folder...

make libpce && make madou1pce_scriptdump
./madou1pce_scriptdump script/orig
