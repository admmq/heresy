;; First install of laptop.scm, from the nonguix installer; see
;; laptop-install.md.  The same system minus what would have to be compiled
;; inside the installer: nonguix's stock kernel, which has substitutes,
;; instead of my-linux-package, and no Amnezia VPN service.  Once it boots,
;; reconfigure with laptop.scm.
;;
;; When run as root, as 'guix system init' is in the installer, it also asks
;; for the passwords of root and user.  Guix only uses them when it creates
;; the accounts, on first boot; later changes made with 'passwd' are kept.
;; Their hashes stay readable in /gnu/store until old system generations are
;; deleted and garbage-collected.

(use-modules (gnu)
             (srfi srfi-1)
             (nongnu packages linux)
             ((heresy srvcs amnezia-vpn-service) #:prefix heresy:))

(define laptop (load "laptop.scm"))

(define (read-new-password prompt)
  "Ask for a password twice, without echoing it, until both entries match
and are not empty."
  (let ((password (getpass prompt)))
    (cond ((string-null? password)
           (display "The password can't be empty.\n" (current-error-port))
           (read-new-password prompt))
          ((string=? password (getpass "Repeat it: "))
           password)
          (else
           (display "They don't match, try again.\n" (current-error-port))
           (read-new-password prompt)))))

(define (password-hash password)
  "Hash PASSWORD with SHA-512 crypt and a random salt."
  (define alphabet
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789./")
  (define state (random-state-from-platform))
  (define salt
    (list->string
     (map (lambda (_)
            (string-ref alphabet (random (string-length alphabet) state)))
          (iota 16))))
  (crypt password (string-append "$6$" salt "$")))

(define install-users
  (if (zero? (getuid))
      (let* ((root (password-hash (read-new-password "New password for root: ")))
             (user (password-hash (read-new-password "New password for user: "))))
        (cons (user-account
               (inherit %root-account)
               (password root))
              (map (lambda (account)
                     (if (string=? (user-account-name account) "user")
                         (user-account
                          (inherit account)
                          (password user))
                         account))
                   (operating-system-users laptop))))
      (operating-system-users laptop)))

(operating-system
  (inherit laptop)
  (kernel linux)
  (users install-users)
  (services (remove (lambda (service)
                      (eq? (service-kind service)
                           heresy:amnezia-vpn-service-type))
                    (operating-system-user-services laptop))))
