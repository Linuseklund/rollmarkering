#!/bin/zsh
# Bygger om Rollmarkering.app från källkoden i den här mappen.
cd "$(dirname "$0")"
A="../Rollmarkering.app"
swiftc -O main.swift -o /tmp/Rollmarkering || exit 1
rm -rf "$A/Contents/Resources/web" && cp -R web "$A/Contents/Resources/web"
cp /tmp/Rollmarkering "$A/Contents/MacOS/Rollmarkering"
xattr -cr "$A"; codesign --force --deep -s - "$A" && echo "Klart."
