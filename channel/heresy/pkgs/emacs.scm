(define-module (heresy pkgs emacs)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages emacs)
  #:use-module ((gnu packages emacs-xyz) #:prefix gnu:)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages glib)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix download)
  #:use-module (guix build-system emacs))

(define-public emacs-stuff
  (let ((commit "91483ab9da7fc342ecd666aa155739ea1ed06810")
        (revision "0"))
    (package
      (name "emacs-stuff")
      (version (git-version "0.0.1" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/admmq/heresy")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "15q4sp3vw7pxhgbrinf9ipijhmapdc3ag9wsayv221qlbs9r0pl1"))))
      (build-system emacs-build-system)
      (arguments
       '(#:include '("\\.el$")
         #:exclude '("build.el"
                     ".dir-locals.el")
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'chdir
             (lambda _
               (chdir "emacs")))
           (add-after 'chdir 'load-org-files
             (lambda _
               (invoke "emacs" "-Q" "--batch" "--load" "build.el"))))))
      (home-page "https://github.com/admmq/herecy")
      (synopsis "My emacs package")
      (description "My emacs package")
      (license license:gpl3+))))

(define-public emacs-exwm
  (package
    (inherit gnu:emacs-exwm)
    (name "heresy-emacs-exwm")
    (synopsis "Emacs X window manager")
    (inputs
     (list xhost dbus))
    (propagated-inputs
     (list gnu:emacs-xelb
           emacs-stuff))
    (arguments
     (list
      #:emacs emacs
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'build 'install-xsession
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((xsessions (string-append #$output "/share/xsessions"))
                     (bin (string-append #$output "/bin"))
                     (exwm-executable (string-append bin "/exwm")))
                ;; Add a .desktop file to xsessions
                (mkdir-p xsessions)
                (mkdir-p bin)
                (make-desktop-entry-file
                 (string-append xsessions "/exwm.desktop")
                 #:name #$name
                 #:comment #$synopsis
                 #:exec exwm-executable
                 #:try-exec exwm-executable)
                ;; Add a shell wrapper to bin
                (with-output-to-file exwm-executable
                  (lambda _
                    (format #t "#!~a ~@
                     ~a +SI:localuser:$USER ~@
                     exec ~a --exit-with-session ~a \"$@\" --eval '~s' ~%"
                            (search-input-file inputs "/bin/sh")
                            (search-input-file inputs "/bin/xhost")
                            (search-input-file inputs "/bin/dbus-launch")
                            (search-input-file inputs "/bin/emacs")
                            '(progn (require 'stuff)
                                    (stuff-exwm-set-variables)
                                    (stuff-exwm-config)))))
                (chmod exwm-executable #o555)))))))))

(define-public emacs-spacious-padding
  ;; named branch is outdated
  (let ((commit "216cf9d38c468f2ce7f8685ba19d4d1fcbb87177")
        (revision "0"))
    (package
      (name "emacs-spacious-padding")
      (version (git-version "0.5.0" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/protesilaos/spacious-padding.git")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "16j568w1w8g2jn4iighvf37mii83x021x2p4dllyki5hz7x5ssjn"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/protesilaos/spacious-padding.git")
      (synopsis "Emacs package for increasing the padding/spacing of frames and windows")
      (description "This package provides a global minor mode to increase
the spacing/padding of Emacs windows and frames.The idea is to make editing
and reading feel more comfortable.  Enable the mode with M-x
spacious-padding-mode.  Adjust the exact spacing values by modifying the user option
spacious-padding-widths.")
      (license license:gpl3+))))
