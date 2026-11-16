package main

import (
	"context"
	"os"
	"os/signal"

	"bb/internal/bitbucket"
	"bb/internal/cli"
)

var version = "dev"

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	dir, _ := os.Getwd()
	code := cli.Run(ctx, os.Args[1:], cli.Env{
		Stdout: os.Stdout, Stderr: os.Stderr, Dir: dir, Version: version,
		NewClient: bitbucket.NewClientFromEnv,
	})
	stop()
	os.Exit(code)
}
