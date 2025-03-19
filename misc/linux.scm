(define-module (my-local-packages)
  #:use-module (guix)
  #:use-module (nongnu packages linux)
  #:use-module (gnu packages linux)
  #:use-module (guix git-download))

(define-public my-linux-package
  (package
    (inherit (customize-linux
              #:linux linux-6.13
              #:defconfig (local-file "defconfig")))
    (name "my-linux-package")
    (version "v6.13")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/torvalds/linux.git")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0ba4cik4aag1l9rvv2mmx987b2sfrz4avxwm1x28ib65chmbcg8l"))))))

my-linux-package
