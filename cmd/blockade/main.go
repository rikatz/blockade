package main

import (
	"fmt"
	golog "log"
	"net/http"
	"net/http/pprof"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/aledbf/blockade/modsecurity"
	"github.com/go-logr/logr"
	"github.com/go-logr/zapr"
	"go.uber.org/zap"
)

var log logr.Logger

func main() {

	zapLog, err := zap.NewDevelopment()
	if err != nil {
		golog.Fatalf("unexpected error configuring logging: %v", err)
	}
	log = zapr.NewLogger(zapLog)

	modsec, err := modsecurity.NewModsecurity()
	if err != nil {
		log.Error(err, "loading modsecurity")
		os.Exit(1)
	}

	modsec.SetServerLogCallback(func(msg string) {
		log.Info(msg)
	})

	go registerProfiler()

	handleSigterm(func(code int) {
		os.Exit(code)
	})
}

func registerProfiler() {
	mux := http.NewServeMux()

	mux.HandleFunc("/debug/pprof/", pprof.Index)
	mux.HandleFunc("/debug/pprof/heap", pprof.Index)
	mux.HandleFunc("/debug/pprof/mutex", pprof.Index)
	mux.HandleFunc("/debug/pprof/goroutine", pprof.Index)
	mux.HandleFunc("/debug/pprof/threadcreate", pprof.Index)
	mux.HandleFunc("/debug/pprof/block", pprof.Index)
	mux.HandleFunc("/debug/pprof/cmdline", pprof.Cmdline)
	mux.HandleFunc("/debug/pprof/profile", pprof.Profile)
	mux.HandleFunc("/debug/pprof/symbol", pprof.Symbol)
	mux.HandleFunc("/debug/pprof/trace", pprof.Trace)

	server := &http.Server{
		Addr:    fmt.Sprintf("127.0.0.1:6060"),
		Handler: mux,
	}

	if err := server.ListenAndServe(); err != nil {
		log.Error(err, "starting profiler server")
		os.Exit(1)
	}
}

type exiter func(code int)

func handleSigterm(exit exiter) {
	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, syscall.SIGTERM)
	<-signalChan
	log.Info("Received SIGTERM, shutting down")

	exitCode := 0
	/*
		if err := Stop(); err != nil {
			log.Error(err, "error during shutdown")
			exitCode = 1
		}
	*/

	log.Info("Handled quit, awaiting Pod deletion")
	time.Sleep(10 * time.Second)
	exit(exitCode)
}
