#!/bin/bash
# Pushes the local commits to GitHub (iggour/blue-lake-game). Double-click in Finder.
cd "$(dirname "$0")/.."
echo "推送到 GitHub ..."
git push origin main
echo
read -n 1 -s -r -p "按任意键关闭"
