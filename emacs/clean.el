;;; clean.el --- Delete tangled files -*- lexical-binding: t; -*-

(let ((src (expand-file-name "src/" (file-name-directory
                                     (or load-file-name buffer-file-name)))))
  (dolist (file (directory-files src t "\\.elc?\\'"))
    (delete-file file)
    (message "%s is deleted" file)))
