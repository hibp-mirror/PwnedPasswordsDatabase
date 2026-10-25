package main

import (
	"bufio"
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

// Same API as https://api.haveibeenpwned.com
const baseURL = "https://hibp.localhost"

func passToAnonK(password string) string {
	sum := sha1.Sum([]byte(password))
	return strings.ToUpper(hex.EncodeToString(sum[:]))
}

func checkAnonK(client *http.Client, hexHash string) (int, error) {
	anonk := hexHash[:5]
	suffix := hexHash[5:]
	resp, err := client.Get(baseURL + "/range/" + anonk)
	if err != nil {
		return 0, fmt.Errorf("range request: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("range API returned status %d", resp.StatusCode)
	}
	scanner := bufio.NewScanner(resp.Body)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, suffix) {
			count, err := strconv.Atoi(strings.TrimPrefix(line, suffix+":"))
			if err != nil {
				return 0, fmt.Errorf("malformed count: %w", err)
			}
			return count, nil
		}
	}
	return 0, nil
}

func main() {
	client := &http.Client{
		Timeout: 10 * time.Second,
		Transport: &http.Transport{
			ForceAttemptHTTP2:     true,
			TLSHandshakeTimeout:   5 * time.Second,
			ResponseHeaderTimeout: 5 * time.Second,
			IdleConnTimeout:       30 * time.Second,
		},
	}
	hexHash := passToAnonK("password")
	count, err := checkAnonK(client, hexHash)
	if err != nil {
		fmt.Fprintf(os.Stderr, "hibp-check: %v\n", err)
		os.Exit(1)
	}
	fmt.Println(count)
	// prints: 52372427
}
