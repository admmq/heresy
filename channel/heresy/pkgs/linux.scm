(define-module (heresy pkgs linux)
  #:use-module (guix)
  #:use-module (nongnu packages linux)
  #:use-module (gnu packages linux)
  #:use-module (guix git-download))

(define-public my-linux-package
  (package
    (inherit (customize-linux
              #:linux linux-6.18))
    (name "my-linux-package")
    (version "v6.18")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/torvalds/linux")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1iwhm85ys6vxwx6nn5nx6m3bwjl5pw7wxm1nyzj2a6nck7vy0nqp"))))))
