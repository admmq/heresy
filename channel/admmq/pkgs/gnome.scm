(define-module (admmq pkgs gnome)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (admmq pkgs python)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-crypto)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages protobuf)
  #:use-module (gnu packages glib)
  #:use-module (guix packages)
  #:use-module (guix git-download))

(define-public komikku-1.58
  (package
    (inherit komikku)
    (name "komikku")
    (version "1.58.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://codeberg.org/valos/Komikku/")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "0inb24r73a97x9z16mh63x6wh8fcsi84gzpvi2zjyl7jd36nsmnv"))))
    (inputs
     (list bash-minimal
           gtk
           libadwaita
           libnotify
           libsecret
           python
           python-beautifulsoup4
           python-brotli
           python-cloudscraper
           python-colorthief
           python-dateparser
           python-emoji
           python-keyring
           python-lxml
           python-magic
           python-natsort
           python-piexif
           python-pillow
           python-pure-protobuf
           python-pycairo
           python-pygobject
           python-rarfile
           python-requests
           python-unidecode
           python-pillow-heif-0.16
           webkitgtk
           webp-pixbuf-loader))))
