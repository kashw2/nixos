package bitbucket

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"testing"
)

type route struct {
	status int
	body   string
	header map[string]string
}

type recorded struct {
	Method string
	Path   string
	Query  map[string][]string
	Body   map[string]any
}

// fakeAPI serves canned responses keyed by "METHOD /path" and records every request.
func fakeAPI(t *testing.T, routes map[string]route) (*Client, *[]recorded) {
	t.Helper()
	var reqs []recorded
	c := newTestClient(t, func(w http.ResponseWriter, r *http.Request) {
		rec := recorded{Method: r.Method, Path: r.URL.Path, Query: r.URL.Query()}
		if b, _ := io.ReadAll(r.Body); len(b) > 0 {
			json.Unmarshal(b, &rec.Body)
		}
		reqs = append(reqs, rec)
		rt, ok := routes[r.Method+" "+r.URL.Path]
		if !ok {
			w.WriteHeader(http.StatusNotFound)
			fmt.Fprintf(w, `{"type":"error","error":{"message":"no route %s %s"}}`, r.Method, r.URL.Path)
			return
		}
		for k, v := range rt.header {
			w.Header().Set(k, v)
		}
		if rt.status != 0 {
			w.WriteHeader(rt.status)
		}
		fmt.Fprint(w, rt.body)
	})
	return c, &reqs
}

func last(reqs *[]recorded) recorded {
	return (*reqs)[len(*reqs)-1]
}

func dig(m map[string]any, keys ...string) any {
	var cur any = m
	for _, k := range keys {
		mm, ok := cur.(map[string]any)
		if !ok {
			return nil
		}
		cur = mm[k]
	}
	return cur
}
