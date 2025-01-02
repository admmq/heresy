(define-module (heresy pkgs python)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (gnu packages)
  #:use-module (gnu packages check)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages image)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages c)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-check)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system python)
  #:use-module (guix build-system pyproject))

(define-public python-pillow-heif-0.16
  (package
    (name "python-pillow-heif")
    (version "0.16.0")
    (source (origin
              (method git-fetch)
              (uri
               (git-reference
                (url "https://github.com/bigcat88/pillow_heif")
                (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32 "1f271r0n9k5gflf4hf8nqncnwzg6wryq76p7w9ffp84qmmabm4jf"))))
    (build-system python-build-system)
    (arguments
     (list #:tests? #f
           #:phases
           #~(modify-phases %standard-phases
             ;; sanity-check phase fail, but the application seems to be working
             (delete 'sanity-check))))
    (inputs
     (list zlib
           ijg-libjpeg
           libheif))
    (home-page "")
    (synopsis "")
    (description
     "")
    (license #f)))

;; todo
;; (define-public python-tcod
;;   (package
;;     (name "python-tcod")
;;     (version "16.2.3")
;;     (source (origin
;;               (method git-fetch)
;;               (uri
;;                (git-reference
;;                 (url "https://github.com/libtcod/python-tcod")
;;                 (commit version)
;;                 (recursive? #t)))
;;               (file-name (git-file-name name version))
;;               (sha256
;;                (base32 "0iq96qbgkqn73i40xj1s0xc4hqxi4b7hcspq6rmai8kg42xzcp8w"))))
;;     (build-system pyproject-build-system)
;;     (arguments
;;      `(#:phases
;;        (modify-phases %standard-phases
;;          ;; sanity-check and check requires the package itself
;;          (delete 'sanity-check)
;;          (delete 'check))))
;;     (native-inputs
;;      (list sdl2-2.0
;;            python-setuptools
;;            python-wheel
;;            python-pcpp
;;            python-pycparser
;;            python-requests
;;            python-pytest-runner
;;            python-pytest-benchmark
;;            python-pytest-cov))
;;     (propagated-inputs
;;      (list python-numpy
;;            python-typing-extensions
;;            python-cffi))
;;     (home-page "https://github.com/libtcod/python-tcod")
;;     (synopsis "Free, fast, portable and uncomplicated API for roguelike developers")
;;     (description
;;      "A collection of tools and algorithms for developing traditional roguelikes.
;; Such as field-of-view, pathfinding, and a tile-based terminal emulator.")
;;     (license license:bsd-3)))

(define-public python-tcod-13.9.1
  (let ((commit "d3419a5b4593c7df1580427fc07616d798c85856")
        (revision "1"))
    (package
      (name "python-tcod")
      (version "13.9.1")
      (source (origin
                (method git-fetch)
                (uri
                 (git-reference
                  (url "https://github.com/libtcod/python-tcod")
                  (commit commit)
                  (recursive? #t)))
                (file-name (git-file-name name version))
                (sha256
                 (base32 "1b0ligrswvz307bbx5jp8wnnqz52v5s4gcgakxy4i3jvccalm2if"))))
      (build-system pyproject-build-system)
      (arguments
       `(#:phases
         (modify-phases %standard-phases
           ;; sanity-check and check requires the package itself
           (delete 'sanity-check)
           (delete 'check))))
      (native-inputs
       (list sdl2-2.0
             python-setuptools
             python-wheel
             python-pcpp
             python-pycparser
             python-requests
             python-pytest-runner
             python-pytest-benchmark
             python-pytest-cov))
      (propagated-inputs
       (list python-numpy
             python-typing-extensions
             python-cffi))
      (home-page "https://github.com/libtcod/python-tcod")
      (synopsis "Free, fast, portable and uncomplicated API for roguelike developers")
      (description
       "A collection of tools and algorithms for developing traditional roguelikes.
Such as field-of-view, pathfinding, and a tile-based terminal emulator.")
      (license license:bsd-2))))

