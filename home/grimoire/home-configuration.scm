;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (guix gexp)
             (gnu home services shells))

(home-environment
  ;; Below is the list of packages that will show up in your
  ;; Home profile, under ~/.guix-home/profile.
  (packages (specifications->packages (list "steam" "brightnessctl"
                                            "google-chrome-stable")))

  ;; Below is the list of Home services.  To search for available
  ;; services, run 'guix home search KEYWORD' in a terminal.
  (services
   (append (list (service home-bash-service-type
                          (home-bash-configuration
                           (aliases '(("grep" . "grep --color=auto")
                                      ("ip" . "ip -color=auto")
                                      ("ll" . "ls -l")
                                      ("ls" . "ls -p --color=auto")))
                           (bashrc (list (local-file "./grimoire/.bashrc"
                                                     "bashrc")))
                           (bash-profile (list (local-file
                                                "./grimoire/.bash_profile"
                                                "bash_profile"))))))
           %base-home-services)))
