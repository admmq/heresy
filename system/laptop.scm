(load "../misc/linux.scm")
(use-modules (gnu) (gnu system nss)
	     (nongnu packages linux)
             (nongnu system linux-initrd)
             ((heresy srvcs) #:prefix heresy:)
             ((heresy pkgs emacs) #:prefix heresy:)
             ((my-local-packages)  #:prefix local:))

(use-service-modules desktop ssh)
(use-package-modules bootloaders certs terminals ssh fonts
		     ratpoison suckless wm version-control
                     emacs emacs-xyz linux xorg)

(operating-system
  (host-name "grimoire")
  (timezone "Europe/Moscow")
  (locale "en_US.utf8")

  (kernel local:my-linux-package)
  (initrd microcode-initrd)
  (firmware (list linux-firmware
                  sof-firmware))

  (bootloader (bootloader-configuration
               (theme
		(grub-theme
		 (image #f)))
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
                     heresy:emacs-exwm
                     heresy:emacs-stuff
                     heresy:emacs-nano-theme
                     heresy:emacs-spacious-padding
                     openssh git kitty bluez xrandr
                     font-google-noto font-google-noto-serif-cjk)
                    %base-packages))

  (services (append (list (service bluetooth-service-type)
                          (service gnome-desktop-service-type))
                    heresy:%desktop-services))

  (name-service-switch %mdns-host-lookup-nss))
