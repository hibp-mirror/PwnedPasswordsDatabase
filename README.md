# Pwned Passwords Database

This is a copy of Troy Hunt's HaveIBeenPwned (HIBP) Password database, downloaded using one of the officially recommended curl method.

## Git Clone

Git clone is slower, but reliably resumable and tracks changes.

```sh
git clone --filter=blob:none --no-checkout https://github.com/hibp-mirror/PwnedPasswordsDatabase.git
cd ./PwnedPasswordsDatabase/

git backfill --min-batch-size=1000
git switch main
```

## Official Download

The full download via `curl` is fast, but downloads every file each time.

```sh
curl --silent --retry 10 --retry-all-errors \
	--remote-name-all \
	--parallel --parallel-max 150 \
	"https://api.pwnedpasswords.com/range/{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}"
```

<https://github.com/HaveIBeenPwned/PwnedPasswordsDownloader/issues/79>
