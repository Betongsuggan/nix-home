// Wake-proxy: a long-running TCP forwarder that fires a Wake-on-LAN magic
// packet when the upstream is unreachable. Designed to front a sleepable
// host (e.g. an AMD ROCm box that suspends when idle).
//
// One process listens on every configured port. Connections are handled
// concurrently; the "upstream alive" state is cached so a browser bursting
// 50 parallel sub-requests doesn't pay 50 probes. WoL fires only when the
// cached state is false and a fresh probe confirms it.
//
// Config via env vars:
//   WAKE_PROXY_MAC          required, MAC of the target NIC
//   WAKE_PROXY_HOST         required, upstream hostname/IP
//   WAKE_PROXY_PORTS        required, comma-separated TCP ports
//   WAKE_PROXY_TIMEOUT_SEC  optional, wait-for-upstream timeout (default 60)
//   WAKE_PROXY_BROADCAST    optional, override WoL broadcast addr

package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
)

type Proxy struct {
	Host      string
	Mac       string
	Broadcast string
	Timeout   time.Duration

	alive  atomic.Bool
	wakeMu sync.Mutex
}

func (p *Proxy) probe(port string) bool {
	c, err := net.DialTimeout("tcp", net.JoinHostPort(p.Host, port), 2*time.Second)
	if err != nil {
		return false
	}
	_ = c.Close()
	return true
}

func (p *Proxy) wake() {
	args := []string{}
	if p.Broadcast != "" {
		args = append(args, "-i", p.Broadcast)
	}
	args = append(args, p.Mac)
	if err := exec.Command("wakeonlan", args...).Run(); err != nil {
		log.Printf("wakeonlan: %v", err)
	}
}

// ensureUpstream blocks until the upstream is reachable on probePort or the
// configured timeout elapses. The "alive" flag is cached so concurrent
// callers don't all wake the host.
func (p *Proxy) ensureUpstream(probePort string) error {
	if p.alive.Load() {
		return nil
	}
	p.wakeMu.Lock()
	defer p.wakeMu.Unlock()
	if p.alive.Load() {
		return nil
	}
	if p.probe(probePort) {
		p.alive.Store(true)
		return nil
	}
	log.Printf("upstream %s unreachable; sending WoL", p.Host)
	p.wake()
	deadline := time.Now().Add(p.Timeout)
	for time.Now().Before(deadline) {
		time.Sleep(1 * time.Second)
		if p.probe(probePort) {
			p.alive.Store(true)
			log.Printf("upstream %s back up", p.Host)
			return nil
		}
	}
	return fmt.Errorf("upstream %s did not come up within %s", p.Host, p.Timeout)
}

func (p *Proxy) backgroundProbe(probePort string, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for range ticker.C {
		p.alive.Store(p.probe(probePort))
	}
}

func (p *Proxy) handle(client net.Conn, port string) {
	defer client.Close()
	if err := p.ensureUpstream(port); err != nil {
		log.Printf("wake-proxy: %v", err)
		return
	}
	addr := net.JoinHostPort(p.Host, port)
	upstream, err := net.DialTimeout("tcp", addr, 5*time.Second)
	if err != nil {
		// Upstream went down between probe and dial; invalidate the cache.
		p.alive.Store(false)
		log.Printf("dial %s: %v", addr, err)
		return
	}
	defer upstream.Close()

	// Bidirectional copy with proper half-close so neither side sees an RST.
	done := make(chan struct{}, 2)
	go func() {
		_, _ = io.Copy(upstream, client)
		if c, ok := upstream.(*net.TCPConn); ok {
			_ = c.CloseWrite()
		}
		done <- struct{}{}
	}()
	go func() {
		_, _ = io.Copy(client, upstream)
		if c, ok := client.(*net.TCPConn); ok {
			_ = c.CloseWrite()
		}
		done <- struct{}{}
	}()
	<-done
	<-done
}

func (p *Proxy) listen(ctx context.Context, port string) error {
	lc := net.ListenConfig{}
	ln, err := lc.Listen(ctx, "tcp", ":"+port)
	if err != nil {
		return err
	}
	defer ln.Close()
	go func() {
		<-ctx.Done()
		_ = ln.Close()
	}()
	log.Printf("listening on :%s -> %s:%s", port, p.Host, port)
	for {
		c, err := ln.Accept()
		if err != nil {
			if ctx.Err() != nil {
				return nil
			}
			log.Printf("accept: %v", err)
			continue
		}
		go p.handle(c, port)
	}
}

func main() {
	mac := os.Getenv("WAKE_PROXY_MAC")
	host := os.Getenv("WAKE_PROXY_HOST")
	portsStr := os.Getenv("WAKE_PROXY_PORTS")
	timeoutStr := os.Getenv("WAKE_PROXY_TIMEOUT_SEC")
	broadcast := os.Getenv("WAKE_PROXY_BROADCAST")

	if mac == "" || host == "" || portsStr == "" {
		log.Fatal("WAKE_PROXY_MAC, WAKE_PROXY_HOST, and WAKE_PROXY_PORTS are required")
	}
	timeoutSec, err := strconv.Atoi(timeoutStr)
	if err != nil || timeoutSec <= 0 {
		timeoutSec = 60
	}
	ports := strings.Split(portsStr, ",")
	if len(ports) == 0 {
		log.Fatal("WAKE_PROXY_PORTS must list at least one port")
	}

	p := &Proxy{
		Host:      host,
		Mac:       mac,
		Broadcast: broadcast,
		Timeout:   time.Duration(timeoutSec) * time.Second,
	}
	p.alive.Store(p.probe(ports[0]))

	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer cancel()

	go p.backgroundProbe(ports[0], 30*time.Second)

	var wg sync.WaitGroup
	for _, port := range ports {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := p.listen(ctx, port); err != nil {
				log.Fatalf("listen %s: %v", port, err)
			}
		}()
	}
	wg.Wait()
}
