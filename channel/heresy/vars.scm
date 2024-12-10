(define-module (heresy vars)
  #:export (%base-substitutes-urls
            %substitutes-urls))

(define %base-substitutes-urls
  (list "https://bordeaux.guix.gnu.org"
        "https://mirrors.sjtug.sjtu.edu.cn/guix"))

(define %substitutes-urls
  (append
   %base-substitutes-urls
   (list
    "http://ci.guix.trop.in"
    "https://substitutes.nonguix.org")))
