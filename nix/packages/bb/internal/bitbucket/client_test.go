package bitbucket

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const (
	testEmail = "dev@example.com"
	testToken = "s3cr3t-token"
)

func clearCredentialEnv(t *testing.T) {
	t.Helper()
	for _, name := range []string{"BITBUCKET_EMAIL", "BITBUCKET_API_TOKEN", "BITBUCKET_EMAIL_FILE", "BITBUCKET_API_TOKEN_FILE"} {
		t.Setenv(name, "")
	}
}

func newTestClient(t *testing.T, h http.HandlerFunc) *Client {
	t.Helper()
	srv := httptest.NewServer(h)
	t.Cleanup(srv.Close)
	return NewClient(srv.URL, testEmail, testToken, srv.Client())
}

func TestNewClientFromEnvPrefersValues(t *testing.T) {
	clearCredentialEnv(t)
	dir := t.TempDir()
	tokenFile := filepath.Join(dir, "token")
	if err := os.WriteFile(tokenFile, []byte("from-file"), 0o600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("BITBUCKET_EMAIL", testEmail)
	t.Setenv("BITBUCKET_API_TOKEN", "from-value")
	t.Setenv("BITBUCKET_API_TOKEN_FILE", tokenFile)

	c, err := NewClientFromEnv()
	if err != nil {
		t.Fatal(err)
	}
	if c.token != "from-value" {
		t.Fatalf("token = %q, want value to win over file", c.token)
	}
}

func TestNewClientFromEnvReadsFilesTrimmed(t *testing.T) {
	clearCredentialEnv(t)
	dir := t.TempDir()
	emailFile := filepath.Join(dir, "email")
	tokenFile := filepath.Join(dir, "token")
	os.WriteFile(emailFile, []byte(testEmail+"\n"), 0o600)
	os.WriteFile(tokenFile, []byte("  "+testToken+"\n\n"), 0o600)
	t.Setenv("BITBUCKET_EMAIL_FILE", emailFile)
	t.Setenv("BITBUCKET_API_TOKEN_FILE", tokenFile)

	c, err := NewClientFromEnv()
	if err != nil {
		t.Fatal(err)
	}
	if c.email != testEmail || c.token != testToken {
		t.Fatalf("got email=%q token=%q", c.email, c.token)
	}
}

func TestNewClientFromEnvMissingNamesVars(t *testing.T) {
	clearCredentialEnv(t)
	_, err := NewClientFromEnv()
	if err == nil {
		t.Fatal("expected error")
	}
	for _, name := range []string{"BITBUCKET_EMAIL", "BITBUCKET_API_TOKEN", "BITBUCKET_EMAIL_FILE", "BITBUCKET_API_TOKEN_FILE"} {
		if !strings.Contains(err.Error(), name) {
			t.Errorf("error %q does not name %s", err, name)
		}
	}
}

func TestDoSendsBasicAuth(t *testing.T) {
	var gotAuth, gotPath string
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		gotAuth = r.Header.Get("Authorization")
		gotPath = r.URL.Path
		fmt.Fprint(w, `{"ok":true}`)
	})
	var out map[string]bool
	if err := c.do(context.Background(), http.MethodGet, "/repositories/ws/repo", nil, nil, &out); err != nil {
		t.Fatal(err)
	}
	want := "Basic " + base64.StdEncoding.EncodeToString([]byte(testEmail+":"+testToken))
	if gotAuth != want {
		t.Fatalf("Authorization = %q, want %q", gotAuth, want)
	}
	if gotPath != "/repositories/ws/repo" || !out["ok"] {
		t.Fatalf("path=%q out=%v", gotPath, out)
	}
}

func TestDoSendsJSONBody(t *testing.T) {
	var got map[string]string
	var contentType string
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		contentType = r.Header.Get("Content-Type")
		json.NewDecoder(r.Body).Decode(&got)
		w.WriteHeader(http.StatusCreated)
		fmt.Fprint(w, `{}`)
	})
	if err := c.do(context.Background(), http.MethodPost, "/x", nil, map[string]string{"a": "b"}, nil); err != nil {
		t.Fatal(err)
	}
	if contentType != "application/json" || got["a"] != "b" {
		t.Fatalf("content-type=%q body=%v", contentType, got)
	}
}

func TestDoReadsRawTextIntoString(t *testing.T) {
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "diff --git a/x b/x\n")
	})
	var out string
	if err := c.do(context.Background(), http.MethodGet, "/diff", nil, nil, &out); err != nil {
		t.Fatal(err)
	}
	if out != "diff --git a/x b/x\n" {
		t.Fatalf("out = %q", out)
	}
}

func TestDoReturnsAPIErrorMessage(t *testing.T) {
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprint(w, `{"type":"error","error":{"message":"x"}}`)
	})
	err := c.do(context.Background(), http.MethodGet, "/x", nil, nil, nil)
	var apiErr *APIError
	if !errors.As(err, &apiErr) || apiErr.Status != 400 || apiErr.Message != "x" {
		t.Fatalf("err = %#v", err)
	}
}

func TestForbiddenMentionsScope(t *testing.T) {
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusForbidden)
		fmt.Fprint(w, `{"type":"error","error":{"message":"Access denied"}}`)
	})
	err := c.do(context.Background(), http.MethodGet, "/x", nil, nil, nil)
	if err == nil || !strings.Contains(err.Error(), "scope") {
		t.Fatalf("err = %v, want a hint about token scope", err)
	}
}

func TestErrorDoesNotLeakCredentials(t *testing.T) {
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		fmt.Fprint(w, `not json`)
	})
	err := c.do(context.Background(), http.MethodGet, "/x", nil, nil, nil)
	if err == nil {
		t.Fatal("expected error")
	}
	encoded := base64.StdEncoding.EncodeToString([]byte(testEmail + ":" + testToken))
	for _, secret := range []string{testToken, testEmail, encoded} {
		if strings.Contains(err.Error(), secret) {
			t.Fatalf("error %q leaks %q", err, secret)
		}
	}
}

func TestPaginateFollowsNext(t *testing.T) {
	var srvURL string
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		page := r.URL.Query().Get("page")
		switch page {
		case "":
			fmt.Fprintf(w, `{"values":[1,2],"next":"%s/items?page=2"}`, srvURL)
		case "2":
			fmt.Fprintf(w, `{"values":[3,4],"next":"%s/items?page=3"}`, srvURL)
		case "3":
			fmt.Fprint(w, `{"values":[5,6]}`)
		}
	})
	srvURL = c.baseURL

	var got []int
	err := c.paginate(context.Background(), "/items", nil, 5, func(raw json.RawMessage) error {
		var n int
		json.Unmarshal(raw, &n)
		got = append(got, n)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if fmt.Sprint(got) != "[1 2 3 4 5]" {
		t.Fatalf("got %v, want first 5 items across pages", got)
	}
}

func TestPaginateRejectsForeignNext(t *testing.T) {
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, `{"values":[1],"next":"https://evil.example/steal"}`)
	})
	err := c.paginate(context.Background(), "/items", nil, 0, func(json.RawMessage) error { return nil })
	if err == nil || !strings.Contains(err.Error(), "evil.example") {
		t.Fatalf("err = %v, want refusal to follow a link to another host", err)
	}
}

func TestNewClientFromEnvIgnoresAPIURL(t *testing.T) {
	clearCredentialEnv(t)
	t.Setenv("BITBUCKET_EMAIL", testEmail)
	t.Setenv("BITBUCKET_API_TOKEN", testToken)
	t.Setenv("BITBUCKET_API_URL", "https://evil.example/2.0")
	c, err := NewClientFromEnv()
	if err != nil {
		t.Fatal(err)
	}
	if c.baseURL != DefaultBaseURL {
		t.Fatalf("baseURL = %q, want credentials only ever sent to %q", c.baseURL, DefaultBaseURL)
	}
}

func TestResolveRejectsSchemeDowngrade(t *testing.T) {
	c := NewClient(DefaultBaseURL, testEmail, testToken, nil)
	if _, err := c.resolve("http://api.bitbucket.org/2.0/items?page=2", nil); err == nil {
		t.Fatal("followed a plain http link with credentials")
	}
	if _, err := c.resolve("https://api.bitbucket.org/2.0/items?page=2", nil); err != nil {
		t.Fatalf("same-origin https link refused: %v", err)
	}
}
