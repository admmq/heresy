(defun remove-needed-files (files)
  (delete "README.org" files))

(defun get-org-files-from-directory (directory)
  (seq-filter (apply-partially 'string-match-p "\.org$")
              (remove-needed-files (directory-files directory))))

(defun get-absolute-org-files-from-directory (directory)
  (mapcar (apply-partially 'concat directory)
          (get-org-files-from-directory directory)))

(let* ((current-working-directory (if (display-graphic-p)
				      (file-name-directory buffer-file-name)
				    (concat (getenv "PWD") "/"))))
  (mapcar #'org-babel-load-file
          (get-absolute-org-files-from-directory current-working-directory))
  (mapcar #'org-babel-load-file
          (get-absolute-org-files-from-directory (concat current-working-directory "src/"))))
