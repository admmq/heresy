(define-module (my-linux-package)
  #:use-module (guix)
  #:use-module (nongnu packages linux)
  #:use-module (gnu packages linux)
  #:use-module (guix git-download))

(define-public my-linux-package
  (package
    (inherit (customize-linux
              #:linux linux-6.16))
    (name "my-linux-package")
    (version "v6.16")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/torvalds/linux")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0j9a4hhlx7a1w8q3h2rhv5iz30xxai1kkrwia855r8d81kpfmmpc"))))))

my-linux-package
