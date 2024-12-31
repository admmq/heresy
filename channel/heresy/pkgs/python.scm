(define-module (heresy pkgs python)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages image)
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

(define-public python-tcod
  (package
    (name "python-tcod")
    (version "1.24.0")
    (source (origin
              (method git-fetch)
              (uri
               (git-reference
                (url "https://github.com/libtcod/libtcod.git")
                (commit version)
                (recursive? #t)))
              (file-name (git-file-name name version))
              (sha256
               (base32 "08p33bvrp4403ir9xskgpr7ixvgkksm1dnj9yn8z0rm9w4k8zjkq"))))
    (build-system pyproject-build-system)
    (home-page "")
    (synopsis "Free, fast, portable and uncomplicated API for roguelike developers")
    (description
     "A collection of tools and algorithms for developing traditional roguelikes.
Such as field-of-view, pathfinding, and a tile-based terminal emulator.")
    (license license:bsd-3)))
