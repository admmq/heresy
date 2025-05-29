(define-module (my-linux-package)
  #:use-module (guix)
  #:use-module (nongnu packages linux)
  #:use-module (gnu packages linux)
  #:use-module (guix git-download))

(define-public my-linux-package
  (package
    (inherit (customize-linux
              #:linux linux-6.14))
    (name "my-linux-package")
    (version "v6.14")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/torvalds/linux")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "117x58ynw6n2cl09jh5q49f2nm64wlfn5r5han8an42y5zmk2ng4"))))))

my-linux-package
