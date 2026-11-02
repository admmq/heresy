(define-module (heresy pkgs waymacs)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages window-management)
  #:use-module (gnu packages xorg)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu))

(define-public waymacs
  (let ((commit "e4a2973fa5477c92aacdc0f9cb5fcf7565d42591")
        (revision "0"))
    (package
      (name "waymacs")
      (version (git-version "0.1" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/admmq/waymacs")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "184yvzqwk1wxwd5mbyq78fasad49a3j8llmz8j60qk4wl3r5qnnm"))))
      (build-system gnu-build-system)
      (arguments
       (list
        #:modules '((guix build emacs-utils)
                    (guix build gnu-build-system)
                    (guix build utils))
        #:imported-modules `(,@%default-gnu-imported-modules
                             (guix build emacs-utils))
        ;; `make check' byte-compiles waymacs.el with warnings as errors;
        ;; `make test' needs foot, wtype, wlrctl and grim, so it is not run.
        #:make-flags
        #~(list (string-append "CC=" #$(cc-for-target))
                (string-append "CXX=" #$(cxx-for-target))
                (string-append "PREFIX=" #$output)
                (string-append "EMACS=" #$(this-package-input "emacs-pgtk")
                               "/bin/emacs")
                ;; where the session file tells Emacs to load waymacs.el from
                (string-append "LISPDIR=" #$output
                               "/share/emacs/site-lisp/waymacs"))
        #:phases
        #~(modify-phases %standard-phases
            (delete 'configure)
            ;; `make install' leaves waymacs.el in the checkout
            (add-after 'install 'install-elisp
              (lambda _
                (let ((lisp-dir (string-append #$output
                                               "/share/emacs/site-lisp/waymacs")))
                  (install-file "lisp/waymacs.el" lisp-dir)
                  (emacs-generate-autoloads #$name lisp-dir)
                  (emacs-byte-compile-directory lisp-dir)))))))
      (native-inputs
       (list pkg-config wayland))
      (inputs
       (list emacs-pgtk libxcb wlroots-0.19))
      (home-page "https://github.com/admmq/waymacs")
      (synopsis "Emacs as a Wayland window manager")
      (description
       "waymacs makes Emacs the window manager of a Wayland session, in the
spirit of EXWM.  Every application window gets an Emacs buffer, and showing
that buffer in an Emacs window shows the application there, so Emacs window
commands, @code{display-buffer-alist} and tab-bar workspaces manage the
applications.  It consists of @command{waymacs}, a small wlroots compositor,
and @file{waymacs.el}, which makes all window management decisions.  The
package also installs a @file{waymacs.desktop} session file for display
managers.")
      (license license:gpl3+))))

waymacs
