(let* ((current-working-directory (if (display-graphic-p)
				      (file-name-directory buffer-file-name)
				    (concat (getenv "PWD") "/")))
       (files-in-directory
	(lambda (directory)
	  (mapcar (apply-partially #'concat (concat directory "/"))
		  (remove "." (remove ".." (directory-files (concat "./" directory)))))))
       (full-files-names
	(lambda (files-strings)
	  (mapcar (apply-partially #'concat current-working-directory)
		  files-strings)))
       (org-to-el
	(lambda (org-files)
	  (mapcar #'org-babel-load-file org-files))))
  (funcall org-to-el
	   (funcall full-files-names
		    (cons "stuff.org"
                          (funcall files-in-directory "src")))))
