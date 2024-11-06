(load "../misc/linux.scm")
(use-modules (gnu) (gnu system nss)
	     (nongnu packages linux)
             (nongnu system linux-initrd)
             ((admmq srvcs) #:prefix admmq:)
             ((admmq pkgs emacs) #:prefix admmq:)
             ((my-local-packages)  #:prefix local:))

(use-service-modules desktop ssh)
(use-package-modules bootloaders certs terminals ssh fonts
		     ratpoison suckless wm version-control
                     emacs emacs-xyz linux)

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
                (comment "System user")
                (group "users")
                (supplementary-groups '("wheel" "netdev"
                                        "audio" "video")))
               %base-user-accounts))

  (packages (append (list
                     emacs
                     emacs-desktop-environment
                     emacs-magit emacs-pdf-tools emacs-evil
                     admmq:emacs-exwm
                     admmq:emacs-stuff
                     admmq:emacs-nano-theme
                     admmq:emacs-spacious-padding
                     openssh git kitty bluez
                     font-google-noto font-google-noto-serif-cjk)
                    %base-packages))

  (services (append (list (service bluetooth-service-type)
                          (service gnome-desktop-service-type))
                    admmq:%desktop-services))

  (name-service-switch %mdns-host-lookup-nss))
