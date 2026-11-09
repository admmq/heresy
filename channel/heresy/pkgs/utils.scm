(define-module (heresy pkgs utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages bootloaders)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages disk)
  #:use-module (gnu packages base)
  #:use-module (gnu packages backup)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gawk)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages haskell-xyz)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system qt)
  #:use-module (guix build-system pyproject))

(define-public woeusb
  (let ((revision "1")
        (commit "4c1f1c9718218c5a22d945a72ed78a2b4a4977eb"))
    (package
      (name "woeusb")
      (version (git-version "5.2.4" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/WoeUSB/WoeUSB")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0ahjnlkcwgy3c8g2ic0nadsbj5r7alrdxva4914nz20iv0frrxhs"))))
      (build-system copy-build-system)
      (arguments
       (list
        #:install-plan
        #~'(("sbin/woeusb" "bin/")
            ("share/man/man1/woeusb.1" "share/man/man1/")
            ("share/woeusb" "share/woeusb"))
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'patch-script
              (lambda _
                (substitute* "sbin/woeusb"
                  (("@@WOEUSB_VERSION@@")
                   #$version)
                  (("^#!/usr/bin/env bash" shebang)
                   (string-append
                    shebang "\n"
                    "export PATH=\""
                    (string-join
                     (search-path-as-list
                      '("bin" "sbin")
                      (list #$@(map cadr (package-inputs this-package))))
                     ":")
                    "${PATH:+:$PATH}\""))))))))
      (inputs
       (list 7zip                       ;optional, for Windows 7 UEFI booting
             coreutils
             dosfstools
             findutils
             gawk
             grep
             grub
             ncurses
             ntfs-3g
             parted
             util-linux
             wget                       ;fetches the UEFI:NTFS image
             wimlib))
      (home-page "https://github.com/WoeUSB/WoeUSB")
      (synopsis "Create bootable Windows USB drives")
      (description
       "WoeUSB creates a bootable Microsoft Windows USB stick from a Windows
installation ISO image or DVD.  It supports Windows Vista and later, both
legacy PC (BIOS) and UEFI booting, and FAT32 or NTFS target file systems.")
      (license license:gpl3+))))

(define-public heresy-backuper
  (let ((revision "0")
        (commit "0c1e899db672f26f882809c89195ed5127b83f57"))
    (package
      (name "heresy-backuper")
      (version (git-version "0.0.1" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/admmq/heresy")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "14m36lpm02vqx371wg9dvknrvvaj5f4imrb27mx8ggymcsgi8k3p"))))
      (build-system pyproject-build-system)
      (arguments (list
                  #:test-flags
                  #~(list "discover" "-s" "tests")

                  #:phases
                  #~(modify-phases %standard-phases
                    (add-after 'unpack 'chdir
                      (lambda _
                        (chdir "apps/Backuper"))))))
      (native-inputs (list python-setuptools python-wheel))
      (home-page "https://github.com/admmq/heresy")
      (synopsis "my backup utility")
      (description "my backup utility")
      (license license:wtfpl2))))

(define-public bino
  (package
    (name "bino")
    (version "2.8")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/marlam/bino")
             (commit (string-append "bino-" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1pzd3xvpj1c9sbwcmnrm90wfjcjr667nkkg6hlnd46s47plvywms"))))
    (build-system qt-build-system)
    (arguments
     (list #:qtbase qtbase
           #:tests? #f))                ;no test suite
    (native-inputs
     (list pandoc                       ;for the HTML manual and man page
           qttools))                    ;for LinguistTools
    (inputs
     (list qtmultimedia
           qtsvg                        ;to load the SVG window icon
           qtwayland))
    (home-page "https://bino3d.org/")
    (synopsis "3D video player")
    (description
     "Bino is a video player with a focus on 3D and Virtual Reality.  It can
play stereoscopic 3D videos and images as well as 180° and 360° surround
videos, with or without 3D, and supports many 3D display modes, including
anaglyph glasses, interlaced displays, and OpenGL quad-buffered stereo.")
    (license license:gpl3+)))
