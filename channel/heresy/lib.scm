(define-module (heresy lib)
  #:use-module (guix git-download)
  #:use-module (guix utils))

(define-public vcs-file?
  ;; Return true if the given file is under version control.
  (or (git-predicate (current-source-directory))
      (const #t)))
