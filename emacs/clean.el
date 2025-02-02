(defun get-el-files-from-directory (directory)
  (seq-filter (apply-partially 'string-match-p "\.el$")
              (directory-files directory)))

(defun remove-needed-files (files)
  (delete "clean.el" (delete "build.el" files)))

(defun get-absolute-el-files-from-directory (directory)
  (mapcar (apply-partially 'concat directory)
          (remove-needed-files (get-el-files-from-directory directory))))

(defun my-delete-file (file)
  (if (file-exists-p file)
      (progn
        (delete-file file)
        (message (concat file " is deleted")))))

(defun delete-el-files (directory)
  (mapcar (apply-partially 'my-delete-file)
          (get-absolute-el-files-from-directory directory)))

(let* ((current-working-directory (if (display-graphic-p)
				      (file-name-directory buffer-file-name)
				    (concat (getenv "PWD") "/"))))
  (delete-el-files current-working-directory)
  (delete-el-files (concat current-working-directory "src/")))

