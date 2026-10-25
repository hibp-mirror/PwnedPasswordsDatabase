/**
 * hibp-check.js — check passwords against the Have I Been Pwned Pwned
 * Passwords API using the k-anonymity range request: only the first 5
 * hex characters of the SHA-1 hash leave the machine.
 *
 * The base URL is taken from the HIPBBaseURL global (set it to another
 * API if needed) and defaults to this server's https://hibp.localhost,
 * a re-implementation of the official HIBP endpoint.
 *
 * Usage:
 *   import Pwned from './hibp-check.js';
 *   globalThis.HIPBBaseURL = 'https://other-api.example'; // optional
 *   let count = await Pwned.count('hunter2');
 */

let Pwned = {};

/** Default range API base URL. */
Pwned.DEFAULT_BASE_URL = "https://hibp.localhost";

/**
 * Resolve the base URL from the HIPBBaseURL global.
 *
 * @throws {Error} if the configured URL does not use https
 * @returns {string}
 */
Pwned._baseURL = function () {
   let url =
      (typeof HIPBBaseURL !== "undefined" && HIPBBaseURL) ||
      (typeof process !== "undefined" && process.env.HIPBBaseURL) ||
      Pwned.DEFAULT_BASE_URL;
   let parsed = new URL(url);
   if (parsed.protocol !== "https:") {
      throw new Error("HIPBBaseURL must use https");
   }
   return url.replace(/\/+$/, "");
};

/**
 * Compute the uppercase SHA-1 hex digest of a string.
 *
 * @param {string} str
 * @returns {Promise<string>}
 */
Pwned.sha1Hex = async function (str) {
   let data = new TextEncoder().encode(str);
   let hash = await crypto.subtle.digest("SHA-1", data);
   return Array.from(new Uint8Array(hash))
      .map(function (b) {
         return b.toString(16).padStart(2, "0");
      })
      .join("")
      .toUpperCase();
};

/**
 * Parse raw range text (SUFFIX:COUNT per line) for the given suffix.
 *
 * @param {string} text — raw range endpoint body
 * @param {string} suffix — the 37-char SHA-1 suffix (uppercase)
 * @returns {number} breach count (0 = not found)
 */
Pwned.parseRange = function (text, suffix) {
   for (let line of text.split("\n")) {
      let trimmed = line.trim();
      if (trimmed === "") {
         continue;
      }
      let colonIdx = trimmed.indexOf(":");
      if (colonIdx === -1) {
         continue;
      }
      if (trimmed.slice(0, colonIdx) === suffix) {
         return parseInt(trimmed.slice(colonIdx + 1), 10);
      }
   }
   return 0;
};

/**
 * Check a password against the HIBP database and return the breach
 * count.
 *
 * @param {string} password — the plaintext password to check
 * @returns {Promise<number>} breach count (0 = not found)
 */
Pwned.count = async function (password) {
   if (typeof password !== "string" || password.length === 0) {
      throw new Error("password must be a non-empty string");
   }

   let hash = await Pwned.sha1Hex(password);
   let prefix = hash.slice(0, 5);
   let suffix = hash.slice(5);

   let resp = await fetch(`${Pwned._baseURL()}/range/${prefix}`, {
      method: "GET",
   }).catch(function (err) {
      throw new Error(`pwnedpasswords API error: ${err.message}`);
   });

   if (!resp.ok) {
      throw new Error(
         `pwnedpasswords API error: ${resp.status} ${resp.statusText}`
      );
   }

   return Pwned.parseRange(await resp.text(), suffix);
};

export default Pwned;
export let count = Pwned.count;
export let parseRange = Pwned.parseRange;
export let sha1Hex = Pwned.sha1Hex;
export let DEFAULT_BASE_URL = Pwned.DEFAULT_BASE_URL;
