(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (gnu home services)
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
                                            "emacs-pgtk"
                                            "vlc"
                                            "openssh"
                                            "nss-certs"
                                            "curl"
                                            "git")))

  (services
   (append (list ;; (service home-bash-service-type
                 ;;          (home-bash-configuration
                 ;;           (aliases '(("ls" . "ls --color=auto")))))
                 (service home-channels-service-type
                          heresy:%channels)
                 ;; Symlinked into $HOME; local-file paths are relative
                 ;; to this file.
                 (service home-files-service-type
                          `((".config/waybar/config.jsonc"
                             ,(local-file "waybar/config.jsonc"))
                            (".config/waybar/style.css"
                             ,(local-file "waybar/style.css"))
                            (".config/swaylock/config"
                             ,(local-file "swaylock/config"
                                          "swaylock-config")))))
           %base-home-services)))
