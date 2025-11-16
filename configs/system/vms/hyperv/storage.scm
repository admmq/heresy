(use-modules (gnu) (gnu system nss)
             (gnu system privilege)
             (gnu services shepherd)
             (gnu packages java)
             ((heresy srvcs) #:prefix heresy:))
(use-service-modules ssh networking avahi dbus samba)
(use-package-modules bootloaders libusb nfs linux)

(define telehost-service-type
  (shepherd-service-type
    'telehost
    (const (shepherd-service
	        (documentation "none")
	        (provision '(telehost))
            (stop  #~(make-kill-destructor))
            (start #~(make-forkexec-constructor
                      (list #$(file-append openjdk17 "/bin/java")
                            "-Xmx256m" "-jar" "/home/user/TeleHostManager.jar")
                      #:log-file "/var/log/telehost.log"))))
    #f
    (description "my bot")))

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
                                                  (value "192.168.1.7/24"))))
                                          (routes
                                           (list (network-route
                                                  (destination "default")
                                                  (gateway "192.168.1.1"))))
                                          (name-servers '("8.8.8.8")))))

                          (service telehost-service-type)

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
security = user
server min protocol = SMB2
server max protocol = SMB3
smb encrypt = auto
ntlm auth = yes
vfs objects = catia fruit streams_xattr
fruit:metadata = stream
fruit:model = MacSamba
fruit:veto_appledouble = no
fruit:posix_rename = yes
fruit:zero_file_id = yes
fruit:wipe_intentionally_left_blank_rfork = yes
fruit:delete_empty_adfiles = yes
fruit:time machine = yes

[storage]
path = /storage
browseable = yes
writable = yes
guest ok = no
read only = no
public = yes
force user = nobody
force group = nogroup
create mask = 0777
directory mask = 0777
")))))
		            heresy:%base-services))

  (name-service-switch %mdns-host-lookup-nss))
