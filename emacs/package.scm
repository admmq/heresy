(define-module (package)
  #:use-module (guix)

  #:use-module (gnu packages image-viewers)
  #:use-module (gnu packages compton)
  #:use-module (gnu packages wm)

  #:use-module ((gnu packages emacs-xyz) #:prefix gnu:)
  #:use-module ((heresy pkgs emacs) #:prefix heresy:)
  #:use-module ((heresy lib) #:prefix heresy:))

(define-public emacs-stuff
  (package
    (inherit heresy:emacs-stuff)
    (name "local-emacs-stuff")
    (source (local-file "." name
                        #:recursive? #t
                        #:select? heresy:vcs-file?))
    (arguments
     '(#:include '("\\.el$")
       #:exclude '("build.el"
                   ".dir-locals.el")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'load-org-files
           (lambda _
             (invoke "emacs" "-Q" "--batch" "--load" "build.el"))))))))

emacs-stuff
