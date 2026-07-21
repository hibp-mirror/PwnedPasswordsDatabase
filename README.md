# Pwned Passwords Database

This is a copy of Troy Hunt's HaveIBeenPwned (HIBP) Password database, downloaded using one of the officially recommended methods:

```sh
curl --silent --retry 10 --retry-all-errors \
	--remote-name-all \
	--parallel --parallel-max 150 \
	"https://api.pwnedpasswords.com/range/{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F}"
```

<https://github.com/HaveIBeenPwned/PwnedPasswordsDownloader/issues/79>
