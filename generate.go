// Command generate renders web/index.html from examples/index.tmpl.html,
// embedding the runnable examples from examples/ with chroma syntax
// highlighting and a truncated real sample of pwnedpasswords/5B/5BAA6.
//
//	go run .
package main

import (
	"bytes"
	"fmt"
	"os"
	"strings"
	"text/template"

	"github.com/alecthomas/chroma/v2"
	"github.com/alecthomas/chroma/v2/formatters/html"
	"github.com/alecthomas/chroma/v2/lexers"
	"github.com/alecthomas/chroma/v2/styles"
)

const (
	jsExample    = "examples/hibp-check.js"
	goExample    = "examples/hibp-check.go"
	shellExample = "my_anonk='5BAA6'\ncurl \"https://hibp.localhost/range/${my_anonk}\""
	rangeFile    = "pwnedpasswords/5B/5BAA6"
	templatePath = "examples/index.tmpl.html"
	outputPath   = "web/index.html"
	highlightCSS = "xcode"
)

type pageData struct {
	JS      string // highlighted JS example
	GO      string // highlighted Go example
	Shell   string // highlighted curl example
	CSS     string // chroma highlight stylesheet
	APIHead string // first lines of the range file
	APITail string // last lines of the range file
}

func main() {
	data, err := buildPageData()
	if err != nil {
		fmt.Fprintf(os.Stderr, "generate: %v\n", err)
		os.Exit(1)
	}

	tmpl := template.Must(template.ParseFiles(templatePath))
	var out bytes.Buffer
	if err := tmpl.Execute(&out, data); err != nil {
		fmt.Fprintf(os.Stderr, "generate: executing template: %v\n", err)
		os.Exit(1)
	}
	if err := os.WriteFile(outputPath, out.Bytes(), 0o644); err != nil {
		fmt.Fprintf(os.Stderr, "generate: writing %s: %v\n", outputPath, err)
		os.Exit(1)
	}
}

func buildPageData() (pageData, error) {
	var pd pageData

	js, err := os.ReadFile(jsExample)
	if err != nil {
		return pd, fmt.Errorf("reading %s: %w", jsExample, err)
	}
	goSrc, err := os.ReadFile(goExample)
	if err != nil {
		return pd, fmt.Errorf("reading %s: %w", goExample, err)
	}
	rangeSrc, err := os.ReadFile(rangeFile)
	if err != nil {
		return pd, fmt.Errorf("reading %s: %w", rangeFile, err)
	}

	formatter := html.New(html.WithClasses(true), html.PreventSurroundingPre(true))
	style := styles.Get(highlightCSS)

	pd.JS = highlight(lexers.Get("javascript"), formatter, style, string(js))
	pd.GO = highlight(lexers.Get("go"), formatter, style, string(goSrc))
	pd.Shell = highlight(lexers.Get("bash"), formatter, style, shellExample)
	var cssBuf bytes.Buffer
	if err := formatter.WriteCSS(&cssBuf, style); err != nil {
		return pd, fmt.Errorf("writing css: %w", err)
	}
	pd.CSS = cssBuf.String()
	pd.APIHead, pd.APITail = rangeSample(string(rangeSrc))
	return pd, nil
}

func highlight(l chroma.Lexer, f chroma.Formatter, style *chroma.Style, src string) string {
	var buf bytes.Buffer
	it, err := l.Tokenise(nil, src)
	if err != nil {
		// Tokenising failures are non-fatal; render the plain source.
		return "<em>" + escapeHTML(src) + "</em>"
	}
	if err := f.Format(&buf, style, it); err != nil {
		return "<em>" + escapeHTML(src) + "</em>"
	}
	return strings.TrimSuffix(buf.String(), "\n")
}

func rangeSample(src string) (head, tail string) {
	lines := strings.Split(strings.ReplaceAll(src, "\r\n", "\n"), "\n")
	if len(lines) < 5 {
		return strings.Join(lines, "\n"), ""
	}
	return strings.Join(lines[:2], "\n"), strings.Join(lines[len(lines)-2:], "\n")
}

func escapeHTML(s string) string {
	return strings.NewReplacer("&", "&amp;", "<", "&lt;", ">", "&gt;").Replace(s)
}
