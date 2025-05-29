(load "../misc/linux.scm")
(load "../emacs/package.scm")
(use-modules (gnu) (gnu system nss)
             (gnu packages image-viewers)
             (gnu packages compton)
             (gnu packages wm)
	     (nongnu packages linux)
             (nongnu system linux-initrd)
             (guix channels)
             (srfi srfi-1)
             ((heresy srvcs) #:prefix heresy:)
             ((heresy pkgs emacs) #:prefix heresy:)
             ((my-linux-package)  #:prefix local:)
             ((local-emacs) #:prefix local:))

(use-service-modules desktop linux)
(use-package-modules bootloaders certs terminals ssh fonts
		     ratpoison suckless wm version-control
                     emacs emacs-xyz linux xorg)

(operating-system
  (host-name "grimoire")
  (timezone "Europe/Moscow")
  (locale "en_US.utf8")

  (kernel local:my-linux-package)
  (kernel-arguments (cons* "modprobe.blacklist=pcspkr,snd_pcsp"
                           "rtw89_pci.disable_clkreq=y" "rtw89_pci.disable_aspm_l1=y" "rtw89_pci.disable_aspm_l1ss=y"
                           "rtw89pci.disable_clkreq=y" "rtw89pci.disable_aspm_l1=y" "rtw89pci.disable_aspm_l1ss=y"
                           "rtw89_core.disable_ps_mode=y"
                           "rtw89core.disable_ps_mode=y"
                           %default-kernel-arguments))
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
                     emacs-spacious-padding
                     emacs-magit emacs-pdf-tools
                     local:emacs-exwm
                     local:emacs-stuff
                     openssh git kitty bluez xrandr
                     feh picom polybar
                     font-google-noto font-google-noto-serif-cjk)
                    %base-packages))

  (services (append (list (service bluetooth-service-type)
                          (service gnome-desktop-service-type))
                    heresy:%desktop-services))

  (name-service-switch %mdns-host-lookup-nss))
