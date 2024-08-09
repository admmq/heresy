(define-module (my-local-packages)
  #:use-module (guix)
  #:use-module (nongnu packages linux)
  #:use-module (gnu packages linux)
  #:use-module (guix git-download))

(define-public my-linux-package
  (package
    (inherit linux-lts)
    (name "my-linux-package")
    (version "v6.6")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/torvalds/linux.git")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1n34v4rq551dffd826cvr67p0l6qwyyjmsq6l98inbn4qqycfi49"))))))

;; my-linux-package
