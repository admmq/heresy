;; guix system image --image-type=iso9660 ./configs/system/home-iso.scm

(use-modules (gnu))

(operating-system
  (inherit (load "home.scm"))
  (initrd base-initrd))
