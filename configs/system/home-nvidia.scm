(use-modules (gnu) (gnu system nss)
             (nongnu packages linux)
             (nongnu packages nvidia)
             (nongnu system linux-initrd)
             (nonguix transformations)
             ((heresy srvcs system) #:prefix heresy:)
             ((heresy pkgs emacs) #:prefix heresy:)
             ((heresy pkgs linux) #:prefix heresy:)
             ((heresy srvcs amnezia-vpn-service) #:prefix heresy:))

(use-service-modules desktop sddm ssh xorg)
(use-package-modules bootloaders certs
                     emacs emacs-xyz)

(define %home-os
  (operating-system
    (host-name "home")
    (timezone "Europe/Moscow")
    (locale "en_US.utf8")

    (kernel heresy:my-linux-package)
    (initrd-modules (append (list "vmd")
                            %base-initrd-modules))
    (initrd microcode-initrd)
    (firmware (list linux-firmware
                    sof-firmware))

    (bootloader (bootloader-configuration
                 (bootloader grub-efi-bootloader)
                 (targets '("/boot/efi"))))

    (file-systems (append
                   (list (file-system
                           (device (file-system-label "ROOT"))
                           (mount-point "/")
                           (type "ext4"))
                         (file-system
                           (device (file-system-label "BOOT"))
                           (mount-point "/boot/efi")
                           (type "vfat")))
                   %base-file-systems))

    (users (cons (user-account
                  (name "user")
                  (comment "λ")
                  (group "users")
                  (supplementary-groups '("wheel" "netdev"
                                          "audio" "video")))
                 %base-user-accounts))

    (packages (append (list
                       emacs emacs-exwm emacs-desktop-environment
                       emacs-magit emacs-pdf-tools
                       heresy:emacs-stuff)
                      %base-packages))

    ;; GDM has known issues with the NVIDIA proprietary driver (see nonguix
    ;; README), so it is replaced with SDDM.
    (services (append (list (service bluetooth-service-type)
                            (service openssh-service-type)
                            (service gnome-desktop-service-type)
                            (service sddm-service-type))
                            ;; (service heresy:amnezia-vpn-service-type))
                      (modify-services heresy:%desktop-services
                        (delete gdm-service-type))))

    (name-service-switch %mdns-host-lookup-nss)))

;; nvda-580 covers Maxwell through Blackwell.  Set
;; #:open-source-kernel-module? #t for Turing and newer (required for
;; Blackwell / GeForce 50 series).
(define nvidia-transform
  (nonguix-transformation-nvidia
   #:driver nvda-580
   #:configure-xorg? sddm-service-type))

(nvidia-transform %home-os)
