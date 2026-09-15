;; guix build --file=Backuper/guix.scm

(use-modules (guix packages)
             (guix gexp)
             (guix build-system pyproject)
             ((guix licenses) #:prefix license:)
             (gnu packages python-build)
             (ice-9 ftw)

             ((heresy lib) #:prefix heresy:))

(package
  (name "backuper")
  (version "0.0.1")
  (source (local-file "." name
                      #:recursive? #t
                      #:select? heresy:vcs-file?))
  (build-system pyproject-build-system)
  (arguments (list #:test-flags #~(list "discover" "-s" "tests")))
  (native-inputs (list python-setuptools python-wheel))
  (home-page "")
  (synopsis "")
  (description "")
  (license #f))
