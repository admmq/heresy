(define-module (admmq pkgs emacs)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix download)
  #:use-module (guix build-system emacs)


  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix cvs-download)
  #:use-module (guix download)
  #:use-module (guix deprecation)
  #:use-module (guix bzr-download)
  #:use-module (guix gexp)
  #:use-module (guix i18n)
  #:use-module (guix git-download)
  #:use-module (guix hg-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system emacs)
  #:use-module (guix build-system perl)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages aspell)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages chez)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages code)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages dictionaries)
  #:use-module (gnu packages djvu)
  #:use-module (gnu packages ebook)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages enchant)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages games)
  #:use-module (gnu packages gawk)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages haskell-apps)
  #:use-module (gnu packages ibus)
  #:use-module (gnu packages java)
  #:use-module (gnu packages julia-xyz)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages telephony)
  #:use-module (gnu packages terminals)
  #:use-module (gnu packages tex)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages tcl)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages tree-sitter)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages lesstif)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages image)
  #:use-module (gnu packages image-viewers)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages lisp-xyz)
  #:use-module (gnu packages lsof)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages music)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages imagemagick)
  #:use-module (gnu packages w3m)
  #:use-module (gnu packages web)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages node)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages acl)
  #:use-module (gnu packages mail)
  #:use-module (gnu packages messaging)
  #:use-module (gnu packages package-management)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages racket)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages scheme)
  #:use-module (gnu packages serialization)
  #:use-module (gnu packages speech)
  #:use-module (gnu packages xiph)
  #:use-module (gnu packages mp3)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages fribidi)
  #:use-module (gnu packages gd)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages password-utils)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages animation)
  #:use-module (gnu packages sphinx)
  #:use-module (gnu packages screen)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages video)
  #:use-module (gnu packages haskell-xyz)
  #:use-module (gnu packages wordnet)
  #:use-module (gnu packages photo)
  #:use-module (gnu packages tor)
  #:use-module (gnu packages uml)
  #:use-module (gnu packages finance)
  #:use-module (gnu packages ocaml)
  #:use-module (gnu packages erlang)
  #:use-module (gnu packages statistics)
  #:use-module (gnu packages libcanberra)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages virtualization)
  #:use-module (gnu packages web-browsers)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (guix utils)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 match))

(define-public emacs-stuff
  (let ((commit "e6d167588e96ec88f3f2ba4007ee3bb94a405407")
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
                  "129zfp54klh3sz7lg3h8fv1056z1dwqa6gf4v0m4kpi68ax0k7kp"))))
      (build-system emacs-build-system)
      (arguments
       '(#:include '("\\.el$")
         #:exclude '("build.el"
                     ".dir-locals.el")
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'load-org-files
             (lambda _
               (invoke
                "emacs" "-Q" "--batch" "--load" "build.el"))))))
      (home-page "https://github.com/admmq/emacs-stuff")
      (synopsis "My emacs package")
      (description "My emacs package")
      (license license:gpl3+))))

(define-public my-emacs-exwm
  (package
    (name "my-emacs-exwm")
    (version "0.30")
    (synopsis "Emacs X window manager")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://elpa.gnu.org/packages/"
                           "exwm-" version ".tar"))
       (sha256
        (base32 "1yscxs0knfb7wz7x6g9nixb6rpn5898q9dpsvk37ayda7nw75b2i"))))
    (build-system emacs-build-system)
    (propagated-inputs
     (list emacs-xelb))
    (inputs
     (list xhost dbus))
    ;; The following functions and variables needed by emacs-exwm are
    ;; not included in emacs-minimal:
    ;; scroll-bar-mode, fringe-mode
    ;; x-display-pixel-width, x-display-pixel-height
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
                            '(cond
                              ((file-exists-p "~/.exwm")
                               (load-file "~/.exwm"))
                              ((not (featurep 'exwm))
                               (require 'exwm)
                               (require 'exwm-config)
                               (exwm-config-example)
                               (message (concat "exwm configuration not found. "
                                                "Falling back to default configuration...")))))))
                (chmod exwm-executable #o555)))))))
    (home-page "https://github.com/ch11ng/exwm")
    (description
     "EXWM is a full-featured tiling X window manager for Emacs built on top
of XELB.")
    (license license:gpl3+)))