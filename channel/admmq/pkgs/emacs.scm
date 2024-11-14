(define-module (admmq pkgs emacs)
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
  (let ((commit "855de9f27906b7ed0b92a06f931ecd77d6525592")
        (revision "0"))
    (package
      (name "emacs-stuff")
      (version (git-version "0.0.1" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/admmq/emacs-stuff")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "1fqzpr7nw4n0wa0wwv2z3nw3xzihfsasn16hhxh93q3dp5padvhd"))))
      (build-system emacs-build-system)
      (arguments
       '(#:include '("\\.el$")
         #:exclude '("build.el"
                     ".dir-locals.el")
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'load-org-files
             (lambda _
               (invoke "emacs" "-Q" "--batch" "--load" "build.el"))))))
      (home-page "https://github.com/admmq/emacs-stuff")
      (synopsis "My emacs package")
      (description "My emacs package")
      (license license:gpl3+))))

(define-public emacs-exwm
  (package
    (inherit gnu:emacs-exwm)
    (name "admmq-emacs-exwm")
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

(define-public emacs-nano-theme
  ;; no named branches
  (let ((commit "ffe414c8af9c673caf8b8b05ba89a229cb9ad48b")
        (revision "0"))
    (package
      (name "emacs-nano-theme")
      (version (git-version "0.3.4" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/rougier/nano-theme.git")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "0wi5snsakpag7lcdndz10x5fxb0yrnignqdx3v4fm5drbk0d7hkr"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/rougier/nano-theme.git")
      (synopsis "GNU Emacs / N Λ N O Theme")
      (description "A consistent theme for GNU Emacs which is based on
Material colors and the dark theme is based on Nord colors.")
      (license license:gpl3+))))

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
