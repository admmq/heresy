;;; Guix package definitions in support of packaging the Amnezia VPN client.
;;; These are staged in a standalone channel; see
;;; local-packages/amnezia.scm for the top-level package.

(define-module (heresy pkgs golang-amnezia)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix build-system go)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages golang-build)
  #:use-module (gnu packages golang-check)
  #:use-module (gnu packages golang-compression)
  #:use-module (gnu packages golang-crypto)
  #:use-module (gnu packages golang-web)
  #:use-module (gnu packages golang-xyz))

;; go-go4-org-netipx comes from (gnu packages golang-web); it is already
;; packaged upstream at the very same commit/hash Xray-core needs.

(define-public go-github-com-ajg-form
  (package
    (name "go-github-com-ajg-form")
    (version "1.5.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/ajg/form")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1d6sxzzf9yycdf8jm5877y0khmhkmhxfw3sc4xpdcsrdlc7gqh5a"))))
    (build-system go-build-system)
    (arguments
     (list #:import-path "github.com/ajg/form"
           ;; The test suite predates Go 1.17's stricter net/url query
           ;; parsing and panics on malformed-query test fixtures.
           #:tests? #f))
    (home-page "https://github.com/ajg/form")
    (synopsis "Go library for encoding/decoding form data")
    (description
     "This package provides a Go library to decode/encode
form data from/to almost any Go type, in the vein of
@code{encoding/json}.")
    (license license:bsd-3)))

(define-public go-github-com-go-chi-render
  (package
    (name "go-github-com-go-chi-render")
    (version "1.0.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/go-chi/render")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0ncbmwaijnrp5pphgd80qyb8z5z1s7l0zb5zcgvg4mn8rh5fhy86"))))
    (build-system go-build-system)
    (arguments
     (list #:import-path "github.com/go-chi/render"))
    (propagated-inputs
     (list go-github-com-ajg-form))
    (home-page "https://github.com/go-chi/render")
    (synopsis "Render HTTP responses for the @code{chi} router")
    (description
     "This package provides helpers for decoding and rendering HTTP
request and response payloads for use with the @code{go-chi/chi} router.")
    (license license:expat)))

(define-public go-github-com-go-gost-relay
  (package
    (name "go-github-com-go-gost-relay")
    (version "0.5.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/go-gost/relay")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0ary7dzqzpp9acz7lqbgjgazq9akcqjkf34c95i6scay8s1x1d2d"))))
    (build-system go-build-system)
    (arguments
     (list #:import-path "github.com/go-gost/relay"))
    (home-page "https://github.com/go-gost/relay")
    (synopsis "GOST relay protocol implementation")
    (description
     "This package provides a Go implementation of the GOST relay
protocol, used to multiplex proxy protocol negotiation over a single
connection.")
    (license license:expat)))

;; go-go4-org-netipx is already packaged upstream in (gnu packages
;; golang-web), at the very same commit/hash Xray-core needs; use that one
;; directly instead of duplicating it here.

(define-public go-github-com-apernet-quic-go
  (let ((commit "6c6cc9bcb716256af2977c4b3b8a2924269e9718")
        (revision "1"))
    (package
      (name "go-github-com-apernet-quic-go")
      (version (git-version "0.59.1" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               ;; The apernet/quic-go GitHub repository was renamed to
               ;; HyNetworks/quic-go; the Go module path stays
               ;; "github.com/apernet/quic-go" (see its go.mod).
               (url "https://github.com/HyNetworks/quic-go")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "061qvnb41mhpavfazakvpl46waprz02ixad4w43ananh2cbx8117"))))
      (build-system go-build-system)
      (arguments
       (list
        #:import-path "github.com/apernet/quic-go"
        ;; The test suite exercises Go's testing/synctest package, which
        ;; panics ("synctest.Run not supported with asynctimerchan!=0")
        ;; under this Go toolchain's default GODEBUG settings; this is a
        ;; test-environment incompatibility, not a code issue, and this
        ;; package is only used here as a source dependency of Xray-core.
        #:tests? #f))
      (propagated-inputs
       (list go-github-com-quic-go-qpack
             go-golang-org-x-crypto
             go-golang-org-x-net
             go-golang-org-x-sync
             go-golang-org-x-sys))
      (native-inputs
       (list go-github-com-stretchr-testify
             go-go-uber-org-mock))
      (home-page "https://github.com/apernet/quic-go")
      (synopsis "QUIC implementation in Go, Apernet/Hysteria fork")
      (description
       "This package provides a Go implementation of the QUIC protocol,
maintained as a fork of @code{quic-go/quic-go} by the Apernet project (used
by Hysteria and Xray-core).")
      (license license:expat))))

(define-public go-github-com-refraction-networking-utls-next
  ;; Xray-core needs ClientHelloID constants (HelloFirefox_148,
  ;; HelloSafari_26_3) added after the 1.8.2 release Guix otherwise has
  ;; packaged; there is no newer tag yet, only this commit.
  (package/inherit go-github-com-refraction-networking-utls
    (name "go-github-com-refraction-networking-utls-next")
    (version "1.8.3-0.20260301010127-aa6edf4b11af")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/refraction-networking/utls")
             (commit "aa6edf4b11af82e110eea845bb2983d30138d651")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1yng724l5fav5birq582lppxak7g7lna39y1623dy5firigdxg40"))))))

(define-public go-github-com-xtls-xray-core
  (package
    (name "go-github-com-xtls-xray-core")
    (version "1.260728.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             ;; Xray-core proper (github.com/xtls/xray-core) does not
             ;; support the AmneziaWG protocol.  Amnezia maintains a fork
             ;; that keeps the upstream module path unchanged (see its
             ;; go.mod) and is meant to be pulled in via a "replace"
             ;; directive; package it under its declared identity so
             ;; consumers importing "github.com/xtls/xray-core/..." find
             ;; it, matching what amnezia-xray-bindings expects.
             (url "https://github.com/amnezia-vpn/amnezia-xray-core")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "18423b3s81jrxj9d8qzpfc45hf1nxilq3knjgdp9g847pi9rjckl"))
       (modules '((guix build utils)))
       (snippet
        #~(begin
            ;; main/commands/all pulls in main/commands/all/tls/ech.go,
            ;; which needs the crypto/hpke standard library package; that
            ;; package isn't available in Guix's current Go toolchain.
            ;; amnezia-xray-bindings only needs the proxy/transport/app
            ;; registrations in main/distro/all, never the CLI command
            ;; dispatcher, so drop that one import.
            (substitute* "main/distro/all/all.go"
              (("_ \"github.com/xtls/xray-core/main/commands/all\"") ""))))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/xtls/xray-core"
      ;; Xray-core's go.mod declares "go 1.26": it uses the Go 1.26
      ;; "new(expr)" builtin extension, and its TLS code references
      ;; crypto/tls curve IDs (SecP256r1MLKEM768 and friends) only added
      ;; to the standard library in Go 1.26.
      #:go go-1.26
      ;; This is consumed as a source library by amnezia-xray-bindings
      ;; (which pulls in essentially all of it via
      ;; main/distro/all); building/testing it standalone is not
      ;; needed and its test suite requires network access.
      #:skip-build? #t
      #:tests? #f))
    (propagated-inputs
     (list go-github-com-amnezia-vpn-amneziawg-go
           go-github-com-andybalholm-brotli
           go-github-com-apernet-quic-go
           go-github-com-cloudflare-circl
           go-github-com-ghodss-yaml
           go-github-com-golang-mock
           go-github-com-google-btree
           go-github-com-google-go-cmp
           go-github-com-google-uuid
           go-github-com-gorilla-websocket
           go-github-com-juju-ratelimit
           go-github-com-klauspost-compress
           go-github-com-klauspost-cpuid-v2
           go-github-com-miekg-dns
           go-github-com-pelletier-go-toml
           go-github-com-pion-dtls-v3
           go-github-com-pion-logging
           go-github-com-pion-stun-v3
           go-github-com-pion-transport-v4
           go-github-com-pires-go-proxyproto
           go-github-com-quic-go-qpack
           go-github-com-refraction-networking-utls-next
           go-github-com-robfig-cron-v3
           go-github-com-sagernet-sing
           go-github-com-sagernet-sing-shadowsocks
           go-github-com-vishvananda-netlink
           go-github-com-vishvananda-netns
           go-github-com-wlynxg-anet
           go-github-com-xtls-reality
           go-go4-org-netipx
           go-golang-org-x-crypto
           go-golang-org-x-exp
           go-golang-org-x-net
           go-golang-org-x-sync
           go-golang-org-x-sys
           go-google-golang-org-genproto-googleapis-rpc
           go-google-golang-org-grpc
           go-google-golang-org-protobuf
           go-gvisor-dev-gvisor
           go-h12-io-socks
           go-lukechampine-com-blake3))
    (home-page "https://github.com/amnezia-vpn/amnezia-xray-core")
    (synopsis "Platform for building proxies, forked for AmneziaWG support")
    (description
     "Xray-core is a platform for building proxies that can bypass network
restrictions, supporting protocols such as VLESS, VMess, Trojan, and
Shadowsocks.  This is the Amnezia VPN project's fork, adding support for
the AmneziaWG transport used elsewhere in the Amnezia VPN client.")
    (license license:mpl2.0)))

(define-public tun2socks
  (package
    (name "tun2socks")
    (version "2.6.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/xjasonlyu/tun2socks")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0c6lg4gz5zaj1hbh9cbdiyshk5nwpkaczvkgkl1a64y19vbhrkkr"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/xjasonlyu/tun2socks/v2"
      #:install-source? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'rename-binary
            (lambda* (#:key outputs #:allow-other-keys)
              ;; main.go lives at the repository root under a "/v2"
              ;; module path with no separate cmd/tun2socks directory,
              ;; so "go install" names the binary after the major
              ;; version suffix ("v2") instead of the module.
              (let ((bin (string-append (assoc-ref outputs "out") "/bin")))
                (rename-file (string-append bin "/v2")
                             (string-append bin "/tun2socks"))))))))
    (native-inputs
     (list go-github-com-stretchr-testify))
    (propagated-inputs
     (list go-github-com-docker-go-units
           go-github-com-go-chi-chi-v5
           go-github-com-go-chi-cors
           go-github-com-go-chi-render
           go-github-com-go-gost-relay
           go-github-com-google-shlex
           go-github-com-google-uuid
           go-github-com-gorilla-schema
           go-github-com-gorilla-websocket
           go-go-uber-org-atomic
           go-go-uber-org-automaxprocs
           go-go-uber-org-zap
           go-golang-org-x-crypto
           go-golang-org-x-sys
           go-golang-org-x-time
           go-golang-zx2c4-com-wireguard
           go-gopkg-in-yaml-v3
           go-gvisor-dev-gvisor))
    (home-page "https://github.com/xjasonlyu/tun2socks")
    (synopsis "TUN interface that proxies traffic through a SOCKS/Shadowsocks server")
    (description
     "Tun2socks provides a TUN interface that transparently proxies all
traffic through a SOCKS4/4A/5, Shadowsocks, or Trojan server, using the
gVisor user-space network stack.  The Amnezia VPN client uses it as one of
the runtime helpers spawned by its privileged service.")
    (license license:expat)))

(define-public amnezia-xray-bindings
  (package
    (name "amnezia-xray-bindings")
    (version "1.4.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/amnezia-vpn/amnezia-xray-bindings")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0wamdzjwbwm2pdb3qwvd10zj6f23cw4pdqwhjwc4irnx7in3gxcn"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "xray_binding"
      #:go go-1.26              ;see go-github-com-xtls-xray-core
      #:install-source? #f
      #:tests? #f                      ;no test suite
      ;; xray-core's transport/internet/browser_dialer package embeds
      ;; dialer.html via //go:embed; go-build-system's GOPATH assembly
      ;; brings that file in as a symlink to the go-github-com-xtls-xray-core
      ;; package's store output, and Go's embed refuses to embed symlinks.
      #:embed-files #~(list "dialer.html")
      #:phases
      #~(modify-phases %standard-phases
          (replace 'build
            (lambda* (#:key import-path #:allow-other-keys)
              (setenv "CGO_ENABLED" "1")
              (with-directory-excursion (string-append "src/" import-path)
                (invoke "go" "build" "-ldflags=-w"
                        "-o" "amnezia_xray.a"
                        "-buildmode=c-archive"))))
          (replace 'install
            (lambda* (#:key import-path outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (src (string-append "src/" import-path))
                     (libdir (string-append out "/lib")))
                (mkdir-p libdir)
                ;; CMake's find_library() expects a "lib" prefix; the
                ;; upstream Conan recipe renames it the same way.
                (copy-file (string-append src "/amnezia_xray.a")
                           (string-append libdir "/libamnezia_xray.a"))
                (install-file (string-append src "/amnezia_xray.h")
                              (string-append out "/include"))))))))
    (propagated-inputs
     (list go-github-com-xtls-xray-core))
    (home-page "https://github.com/amnezia-vpn/amnezia-xray-bindings")
    (synopsis "C bindings for Xray-core, as a static library")
    (description
     "This package builds Xray-core as a C archive (a static library plus
a generated C header), for embedding into non-Go applications.  It is used
by the Amnezia VPN client's privileged helper service to speak the
VLESS/VMess/Trojan/Shadowsocks protocols implemented by Xray-core.")
    (license license:gpl3+)))
