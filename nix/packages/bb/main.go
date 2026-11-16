package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"

	"bb/internal/bitbucket"
	"bb/internal/cli"
	"bb/internal/mcpserver"

	"github.com/modelcontextprotocol/go-sdk/mcp"
)

var version = "dev"

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	if len(os.Args) > 1 && os.Args[1] == "mcp" {
		err := mcpserver.New(bitbucket.NewClientFromEnv, version).Run(ctx, &mcp.StdioTransport{})
		stop()
		if err != nil {
			fmt.Fprintln(os.Stderr, "bb mcp:", err)
			os.Exit(1)
		}
		return
	}
	dir, _ := os.Getwd()
	code := cli.Run(ctx, os.Args[1:], cli.Env{
		Stdout: os.Stdout, Stderr: os.Stderr, Dir: dir, Version: version,
		NewClient: bitbucket.NewClientFromEnv,
	})
	stop()
	os.Exit(code)
}
