(use-modules (guix)
             (guix git-download)
             (guix build-system emacs)
             ((guix licenses) #:prefix license:))

(package
  (name "emacs-stuff")
  (version "0.0.1")
  (source (local-file "." "emacs-stuff-checkout"
                      #:recursive? #t
                      #:select? (git-predicate (current-source-directory))))
  (build-system emacs-build-system)
  (arguments
   '(#:include '("\\.el$")
     #:exclude '("clean.el"
                 ".dir-locals.el")
     #:phases
     (modify-phases %standard-phases
       (add-after 'unpack 'tangle-org-files
         (lambda _
           (invoke "emacs" "-Q" "--batch" "--load" "stuff.el"))))))
  (home-page "https://github.com/admmq/heresy")
  (synopsis "My literate Emacs config")
  (description "My literate Emacs config.")
  (license license:wtfpl2))
