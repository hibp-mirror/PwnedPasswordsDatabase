#!/bin/sh
set -eu

g_dir='pwnedpasswords'
echo "git add 16^5 (1,048,576) files in 256 batches of 4096..."
echo ""
for a in 0 1 2 3 4 5 6 7 8 9 A B C D E F; do
	for b in 0 1 2 3 4 5 6 7 8 9 A B C D E F; do
		echo git add "./${g_dir}/${a}${b}/"
		git add "./${g_dir}/${a}${b}/"
		echo git commit -m "chore: add ./${g_dir}/${a}${b}/"
		git commit -m "chore: add ./${g_dir}/${a}${b}/"
	done
done

echo ""
echo "Done"
