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
  (let ((commit "c4cefde57ffe6fbcebdecac964c8447eb06463d2")
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
                  "0qv83z9jwsgzrfjvin18ahgq0l79z8z04ajzazsh8mqpcyv87p9q"))))
      (build-system emacs-build-system)
      (arguments
       '(#:include '("\\.el$")
         #:exclude '("clean.el"
                     ".dir-locals.el")
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'chdir
             (lambda _
               (chdir "emacs")))
           (add-after 'chdir 'load-org-files
             (lambda _
               (invoke "emacs" "-Q" "--batch" "--load" "stuff.el"))))))
      (home-page "https://github.com/admmq/heresy")
      (synopsis "My emacs package")
      (description "My emacs package")
      (license license:wtfpl2))))

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
