#!/bin/sh
set -eu

g_dir='pwnedpasswords'
echo "Downloading 16^5 (1,048,576) files in 256 batches of 4096..."
echo ""
for a in 0 1 2 3 4 5 6 7 8 9 A B C D E F; do
	for b in 0 1 2 3 4 5 6 7 8 9 A B C D E F; do
		# make the batch directory
		mkdir -p "./${g_dir}/${a}${b}"

		# download the batch of 4096, hundreds at a time
		printf "    downloading %s{0..F}{0..F}{0..F}...\n" "${a}${b}"
		(
			cd "./${g_dir}/${a}${b}/"
			curl --silent --retry 10 --retry-all-errors \
				--remote-name-all \
				--parallel --parallel-max 150 \
				"https://api.pwnedpasswords.com/range/${a}${b}{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}"
		)
	done
done

echo ""
echo "Done"
