(use-modules (guix packages)
             (guix gexp)
             (guix build-system gnu)
             ((guix licenses) #:prefix license:)
             (gnu packages backup)
             (gnu packages cpp)
             ((heresy lib) #:prefix heresy:))

(package
  (name "heresy-backuper")
  (version "1.0.0")
  (source (local-file "." name
                      #:recursive? #t
                      #:select? heresy:vcs-file?))
  (build-system gnu-build-system)
  (arguments
   (list
    #:tests? #f
    #:phases
    #~(modify-phases %standard-phases
        (delete 'configure)
        (replace 'build
          (lambda _
            (invoke "g++"
                    "-std=c++17" "-O2" "main.cc"
                    "-larchive"
                    "-o" "heresy-backuper")))
        (replace 'install
          (lambda _
            (install-file "heresy-backuper" (string-append #$output "/bin")))))))
  (native-inputs (list cli11))
  (inputs (list libarchive))
  (home-page "")
  (synopsis "")
  (description "")
  (license #f))
