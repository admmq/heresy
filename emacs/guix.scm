(use-modules (guix)
             ((admmq pkgs emacs) #:prefix admmq:)
             ((admmq lib) #:prefix admmq:))

(package
  (inherit admmq:emacs-stuff)
  (source (local-file "." "emacs-stuff-local-build"
                      #:recursive? #t
                      #:select? admmq:vcs-file?)))
