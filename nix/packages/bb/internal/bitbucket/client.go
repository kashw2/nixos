// Package bitbucket is a small Bitbucket Cloud REST 2.0 client for pull request work.
package bitbucket

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

const DefaultBaseURL = "https://api.bitbucket.org/2.0"

var ErrMissingCredentials = errors.New("bitbucket credentials not set: set BITBUCKET_EMAIL and BITBUCKET_API_TOKEN, or BITBUCKET_EMAIL_FILE and BITBUCKET_API_TOKEN_FILE")

type Client struct {
	baseURL string
	email   string
	token   string
	http    *http.Client
}

func NewClient(baseURL, email, token string, hc *http.Client) *Client {
	if baseURL == "" {
		baseURL = DefaultBaseURL
	}
	if hc == nil {
		hc = &http.Client{Timeout: 60 * time.Second}
	}
	return &Client{baseURL: strings.TrimRight(baseURL, "/"), email: email, token: token, http: hc}
}

// NewClientFromEnv reads credentials from BITBUCKET_EMAIL / BITBUCKET_API_TOKEN, falling back to
// the *_FILE variants so secrets can come from sops-managed files.
func NewClientFromEnv() (*Client, error) {
	email, err := credential("BITBUCKET_EMAIL")
	if err != nil {
		return nil, err
	}
	token, err := credential("BITBUCKET_API_TOKEN")
	if err != nil {
		return nil, err
	}
	if email == "" || token == "" {
		return nil, ErrMissingCredentials
	}
	return NewClient("", email, token, nil), nil
}

func credential(name string) (string, error) {
	if v := strings.TrimSpace(os.Getenv(name)); v != "" {
		return v, nil
	}
	path := os.Getenv(name + "_FILE")
	if path == "" {
		return "", nil
	}
	b, err := os.ReadFile(path)
	if err != nil {
		return "", fmt.Errorf("reading %s_FILE: %w", name, err)
	}
	return strings.TrimSpace(string(b)), nil
}

type APIError struct {
	Status  int
	Message string
}

func (e *APIError) Error() string {
	msg := fmt.Sprintf("bitbucket: %d: %s", e.Status, e.Message)
	if e.Status == http.StatusForbidden {
		msg += " (the API token may lack the scope this operation needs)"
	}
	return msg
}

// resolve accepts an API path or an absolute link returned by the API, refusing any other scheme or
// host so the Authorization header is only ever sent to Bitbucket, and never over plain http.
func (c *Client) resolve(pathOrURL string, q url.Values) (string, error) {
	if !strings.HasPrefix(pathOrURL, "http://") && !strings.HasPrefix(pathOrURL, "https://") {
		u := c.baseURL + pathOrURL
		if len(q) > 0 {
			u += "?" + q.Encode()
		}
		return u, nil
	}
	link, err := url.Parse(pathOrURL)
	if err != nil {
		return "", err
	}
	base, _ := url.Parse(c.baseURL)
	if link.Scheme != base.Scheme || link.Host != base.Host {
		return "", fmt.Errorf("refusing to follow link to %s://%s outside %s", link.Scheme, link.Host, c.baseURL)
	}
	return pathOrURL, nil
}

func (c *Client) send(ctx context.Context, method, pathOrURL string, q url.Values, in any) (*http.Response, error) {
	target, err := c.resolve(pathOrURL, q)
	if err != nil {
		return nil, err
	}
	var body io.Reader
	if in != nil {
		b, err := json.Marshal(in)
		if err != nil {
			return nil, err
		}
		body = bytes.NewReader(b)
	}
	req, err := http.NewRequestWithContext(ctx, method, target, body)
	if err != nil {
		return nil, err
	}
	req.SetBasicAuth(c.email, c.token)
	req.Header.Set("Accept", "application/json")
	if in != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := c.http.Do(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode >= 300 {
		defer resp.Body.Close()
		return nil, readAPIError(resp)
	}
	return resp, nil
}

func readAPIError(resp *http.Response) error {
	raw, _ := io.ReadAll(io.LimitReader(resp.Body, 64<<10))
	var parsed struct {
		Error struct {
			Message string `json:"message"`
			Detail  any    `json:"detail"`
		} `json:"error"`
	}
	msg := http.StatusText(resp.StatusCode)
	if json.Unmarshal(raw, &parsed) == nil && parsed.Error.Message != "" {
		msg = parsed.Error.Message
		if d, ok := parsed.Error.Detail.(string); ok && d != "" {
			msg += ": " + d
		}
	}
	return &APIError{Status: resp.StatusCode, Message: msg}
}

// do sends a request and decodes the response into out: a *string receives the raw body, any other
// non-nil pointer is JSON-decoded.
func (c *Client) do(ctx context.Context, method, pathOrURL string, q url.Values, in, out any) error {
	resp, err := c.send(ctx, method, pathOrURL, q, in)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	return decode(resp, out)
}

func decode(resp *http.Response, out any) error {
	switch v := out.(type) {
	case nil:
		_, err := io.Copy(io.Discard, resp.Body)
		return err
	case *string:
		b, err := io.ReadAll(resp.Body)
		*v = string(b)
		return err
	default:
		return json.NewDecoder(resp.Body).Decode(out)
	}
}

// maxPageLen is the largest page size every endpoint used here accepts.
const maxPageLen = 50

// paginate calls each for up to limit values (all when limit <= 0), following "next" links.
func (c *Client) paginate(ctx context.Context, path string, q url.Values, limit int, each func(json.RawMessage) error) error {
	if q == nil {
		q = url.Values{}
	}
	pageLen := maxPageLen
	if limit > 0 && limit < pageLen {
		pageLen = limit
	}
	q.Set("pagelen", strconv.Itoa(pageLen))

	next, query, count := path, q, 0
	for {
		var page struct {
			Values []json.RawMessage `json:"values"`
			Next   string            `json:"next"`
		}
		if err := c.do(ctx, http.MethodGet, next, query, nil, &page); err != nil {
			return err
		}
		for _, v := range page.Values {
			if limit > 0 && count >= limit {
				return nil
			}
			if err := each(v); err != nil {
				return err
			}
			count++
		}
		if page.Next == "" || (limit > 0 && count >= limit) {
			return nil
		}
		next, query = page.Next, nil
	}
}
