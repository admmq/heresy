(define-module (admmq pkgs emacs)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix download)
  #:use-module (guix build-system emacs))

(define-public emacs-stuff
  (let ((commit "e6d167588e96ec88f3f2ba4007ee3bb94a405407")
        (revision "0"))
    (package
      (name "emacs-stuff")
      (version (git-version "0.0.1" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/admmq/emacs-stuff")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "129zfp54klh3sz7lg3h8fv1056z1dwqa6gf4v0m4kpi68ax0k7kp"))))
      (build-system emacs-build-system)
      (arguments
       '(#:include '("\\.el$")
         #:exclude '("build.el"
                     ".dir-locals.el")
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'load-org-files
             (lambda _
               (invoke
                "emacs" "-Q" "--batch" "--load" "build.el"))))))
      (home-page "https://github.com/admmq/emacs-stuff")
      (synopsis "My emacs package")
      (description "My emacs package")
      (license license:gpl3+))))
