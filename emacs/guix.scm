(use-modules (guix)
             ((heresy pkgs emacs) #:prefix heresy:)
             ((heresy lib) #:prefix heresy:))

(package
  (inherit heresy:emacs-stuff)
  (source (local-file "." "emacs-stuff-local-build"
                      #:recursive? #t
                      #:select? heresy:vcs-file?)))
