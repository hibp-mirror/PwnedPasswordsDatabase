// Same API as https://api.haveibeenpwned.com
let baseUrl = 'https://hibp.localhost';

async function passToAnonK(password) {
   let sum = await crypto.subtle.digest(
      "SHA-1", new TextEncoder().encode(password)
   );
   let hex = Array.from(new Uint8Array(sum))
      .map(function (b) {
         return b.toString(16).padStart(2, "0");
      })
      .join("")
      .toUpperCase();
   return hex;
}

async function checkAnonK(hexHash) {
   let anonk = hexHash.slice(0, 5);
   let suffix = hexHash.slice(5);
   let resp = await fetch(`${baseUrl}/range/${anonk}`);
   if (resp.status !== 200) {
      throw new Error("range API returned status " + resp.status);
   }
   let text = await resp.text();
   let lines = text.split("\n");
   for (let line of lines) {
      if (line.startsWith(suffix)) {
         let parts = line.split(":");
         return Number(parts[1]);
      }
   }
   return 0;
}

let hexHash = await passToAnonK("password");
let count = await checkAnonK(hexHash);
// count === 52372427
console.log(count);
