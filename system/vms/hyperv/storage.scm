(use-modules (gnu) (gnu system nss)
             (gnu system privilege)
             ((heresy srvcs) #:prefix heresy:))
(use-service-modules ssh networking avahi dbus samba)
(use-package-modules bootloaders libusb nfs linux)

(operating-system
  (initrd-modules (append (list "hv_storvsc" "hv_vmbus" "hv_utils")
                          %base-initrd-modules))
  (host-name "storage")
  (timezone "Europe/Moscow")
  (locale "en_US.utf8")

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
                (supplementary-groups '("wheel" "netdev")))
               %base-user-accounts))

  (packages %base-packages)

  (services (append (list (service openssh-service-type)
                          ;; Add udev rules for MTP devices so that non-root users can access
                          ;; them.
                          (simple-service 'mtp udev-service-type (list libmtp))

                          ;; Allow desktop users to also mount NTFS and NFS file systems
                          ;; without root.
                          (simple-service 'mount-setuid-helpers privileged-program-service-type
                                          (map file-like->setuid-program
                                               (list (file-append nfs-utils "/sbin/mount.nfs")
                                                     (file-append ntfs-3g "/sbin/mount.ntfs-3g"))))

                          (service static-networking-service-type
                                   (list (static-networking
                                          (addresses
                                           (list (network-address
                                                  (device "eth0")
                                                  (value "192.168.1.3/24"))))
                                          (routes
                                           (list (network-route
                                                  (destination "default")
                                                  (gateway "192.168.1.1"))))
                                          (name-servers '("8.8.8.8")))))

                          ;; The D-Bus clique.
                          (service avahi-service-type)
                          (service polkit-service-type)
                          (service dbus-root-service-type)
                          (service ntp-service-type)
                          (service samba-service-type (samba-configuration
                                                       (enable-smbd? #t)
                                                       (config-file (plain-file "smb.conf" "\
[global]
map to guest = Bad User
logging = syslog@1

[Storage]
path = /Storage
browseable = yes
writable = yes
guest ok = no
read only = no")))))
		    heresy:%base-services))

  (name-service-switch %mdns-host-lookup-nss))
