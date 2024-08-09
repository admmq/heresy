(load "./linux.scm")
(use-modules (gnu) (gnu system nss)
	     (nongnu packages linux)
             (nongnu system linux-initrd)
             ((admmq srvcs) #:prefix admmq:)
             ((admmq pkgs emacs) #:prefix admmq:)
             ((my-local-packages)  #:prefix local:))

(use-service-modules desktop ssh)
(use-package-modules bootloaders certs
		     emacs emacs-xyz
		     ratpoison suckless wm
                     xorg)

(operating-system
  (host-name "grimoire")
  (timezone "Europe/Moscow")
  (locale "en_US.utf8")

  (kernel local:my-linux-package)
  (initrd microcode-initrd)
  (firmware (list linux-firmware
                  sof-firmware))

  (bootloader (bootloader-configuration
               (bootloader grub-efi-bootloader)
               (targets '("/boot/efi"))))

  (file-systems (append
                 (list (file-system
                         (device (file-system-label "my-root"))
                         (mount-point "/")
                         (type "ext4"))
                       (file-system
                         (device (uuid "A5DD-CF6E" 'fat))
                         (mount-point "/boot/efi")
                         (type "vfat")))
                 %base-file-systems))

  (users (cons (user-account
                (name "user")
                (comment "something matters")
                (group "users")
                (supplementary-groups '("wheel" "netdev"
                                        "audio" "video")))
               %base-user-accounts))

  (packages (append (list
                     ;; emacs emacs-exwm emacs-desktop-environment
                     emacs admmq:my-emacs-exwm emacs-desktop-environment
                     emacs-pdf-tools
                     admmq:emacs-stuff
                     xterm)
                    %base-packages))

  (services (append (list (service openssh-service-type)
                          (service bluetooth-service-type)
                          (service gnome-desktop-service-type))
                    admmq:%desktop-services))

  (name-service-switch %mdns-host-lookup-nss))
