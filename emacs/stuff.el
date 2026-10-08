;;; stuff.el --- My literate Emacs config  -*- lexical-binding: t; -*-

;; Author: Adam
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.1"))
;; URL: https://github.com/admmq/heresy

;;; Commentary:

;; Yet another attempt to make a literate config for my favorite text
;; "operating system".  I tried to make it cross platform, but my main
;; focus is Guix.
;;
;; The modules live in src/*.org.  This file is plain elisp so the
;; package can be installed straight from git (e.g. with `package-vc')
;; without a build step: on load it tangles every module whose .el is
;; missing or older than its .org, then requires it.

;;; Code:

(eval-and-compile
  (defconst stuff-directory
    (file-name-directory (or (macroexp-file-name) buffer-file-name))
    "Directory containing stuff.el.")

  (defconst stuff-modules '("packages" "config" "exwm")
    "Modules in src/, loaded in this order.")

  (defun stuff-tangle-module (module)
    "Tangle src/MODULE.org into src/MODULE.el if it is out of date."
    (let ((org (expand-file-name (format "src/%s.org" module) stuff-directory))
          (el (expand-file-name (format "src/%s.el" module) stuff-directory)))
      (when (file-newer-than-file-p org el)
        (require 'ob-tangle)
        (org-babel-tangle-file org el "emacs-lisp\\|elisp")
        ;; Don't let a stale .elc shadow the freshly tangled file.
        (let ((elc (concat el "c")))
          (when (file-exists-p elc)
            (delete-file elc))))))

  (mapc #'stuff-tangle-module stuff-modules))

(require 'stuff/packages (expand-file-name "src/packages" stuff-directory))
(require 'stuff/config (expand-file-name "src/config" stuff-directory))
(require 'stuff/exwm (expand-file-name "src/exwm" stuff-directory))

(provide 'stuff)

;;; stuff.el ends here
