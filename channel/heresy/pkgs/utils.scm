(define-module (heresy pkgs utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages bootloaders)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages disk)
  #:use-module (gnu packages base)
  #:use-module (gnu packages backup)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages python-build)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system trivial)
  #:use-module (guix build-system pyproject))

(define-public woeusb
  (let ((revision "0")
	;; named branch is outdated
	(commit "34b400d99d3c4089f487e1d4f7d71970b2d4429e"))
    (package
      (name "woeusb")
      (version (git-version "0.0.0" revision commit))
      (source
       (origin
	 (method git-fetch)
	 (uri (git-reference
	       (url "https://github.com/WoeUSB/WoeUSB.git")
	       (commit commit)))
	 (file-name (git-file-name name version))
	 (sha256
	  (base32 "05ghja2rpn4kqak9yll398na54dscsfnm3z5f2pi54lan98wzimh"))))
      (build-system trivial-build-system)
      (inputs
       (list ntfs-3g grub ncurses parted coreutils util-linux wimlib))
      (arguments
       `(#:modules ((guix build utils))
	 #:builder
	 (begin
	   (use-modules (guix build utils))
	   ;; copy source
	   (copy-recursively (assoc-ref %build-inputs "source") ".")
	   ;; patch source
	   (substitute* "sbin/woeusb"
	     (("tput sgr0") (string-append (assoc-ref %build-inputs "ncurses")
					   "/bin/tput"
					   " sgr0"))
	     (("parted --script")
	      (string-append (assoc-ref %build-inputs "parted")
			     "/sbin/parted --script"))
	     (("parted \\\\")
	      (string-append (assoc-ref %build-inputs "parted")
			     "/sbin/parted \\"))
	     (("grub-install") (string-append (assoc-ref %build-inputs "grub")
					      "/sbin/grub-install"))
	     (("command -v mkntfs") (string-append
				     "command -v "
				     (assoc-ref %build-inputs "ntfs-3g")
				     "/sbin/mkntfs"))
	     (("command_mkntfs_ref=mkntfs") (string-append
					     "command_mkntfs_ref="
					     (assoc-ref %build-inputs "ntfs-3g")
					     "/sbin/mkntfs"))
	     (("readlink \\\\") (string-append
				 (assoc-ref %build-inputs "coreutils")
				 "/bin/readlink \\"))
	     (("wimlib-imagex") (string-append
				 (assoc-ref %build-inputs "wimlib")
				 "/bin/wimlib-imagex"))
	     ;; could not find partprobe package
	     ;; as i see this command never used in the program
	     (("partprobe \\\\") "\\"))
	   ;; install phase
	   (install-file "sbin/woeusb" (string-append %output "/bin"))
	   #t)))
      (home-page "https://github.com/WoeUSB/WoeUSB")
      (synopsis "A Microsoft Windows® USB installation media preparer for GNU+Linux")
      (description "Very usefull package for anyone who wants to make a bootable Windows® USB stick
using free and open source operating system.")
      (license license:gpl3+))))

(define-public heresy-backuper
  (let ((revision "0")
        (commit "747bf4cbf8f82bb06010cae31d08a8f6121d63a4"))
    (package
      (name "heresy-backuper")
      (version (git-version "0.0.1" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/admmq/heresy")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "110rmzjjkpw3jh07p8s1jzsqb9rny89z1czb5ss030hb382lwpqq"))))
      (build-system pyproject-build-system)
      (arguments (list
                  #:test-flags
                  #~(list "discover" "-s" "tests")

                  #:phases
                  #~(modify-phases %standard-phases
                    (add-after 'unpack 'chdir
                      (lambda _
                        (chdir "scripts/Backuper"))))))
      (native-inputs (list python-setuptools python-wheel))
      (home-page "https://github.com/admmq/heresy")
      (synopsis "my backup utility")
      (description "my backup utility")
      (license license:wtfpl2))))
