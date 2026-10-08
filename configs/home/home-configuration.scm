(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (gnu home services shells)
             (gnu home services guix)
             (guix gexp)
             (guix channels)
             ((heresy vars) #:prefix heresy:))

(home-environment
  (packages (specifications->packages (list "guile"
                                            "google-chrome-stable"
                                            "emacs-yasnippet"
                                            "emacs-magit"
                                            "emacs-stuff"
                                            "keepassxc"
                                            "emacs-pdf-tools"
                                            "emacs-emojify"
                                            "emacs-vterm"
                                            "emacs-evil"
                                            "emacs"
                                            "vlc"
                                            "nss-certs"
                                            "curl"
                                            "git")))

  (services
   (append (list ;; (service home-bash-service-type
                 ;;          (home-bash-configuration
                 ;;           (aliases '(("ls" . "ls --color=auto")))))
                 (service home-channels-service-type
                          heresy:%channels))
           %base-home-services)))
