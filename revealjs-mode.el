;;; revealjs-mode.el --- Minor mode to navigate and edit HTML files
;;; containing RevealJS slide sets

;; Copyright (C) 2013 Christian Johansen

;; Authors: Christian Johansen <christian@cjohansen.no>
;; Keywords: org-mode revealjs slides presentation

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(defvar revealjs-mode-map (make-sparse-keymap)
  "revealjs-mode keymap")

(defun revealjs--beginning-of-slide ()
  (interactive)
  (if (search-forward "<h" nil t)
      (left-char 2)))

(defun revealjs--beginning-of-slidep ()
  (let ((curpos (point)))
    (save-excursion
      (revealjs--beginning-of-slide)
      (eq curpos (point)))))

(defun revealjs-next-slide (num)
  (interactive "p")
  (-dotimes num (lambda (n)
                  (end-of-line)
                  (if (search-forward "<section" nil t)
                      (revealjs--beginning-of-slide)))))

(defun revealjs-previous-slide (num)
  (interactive "p")
  (if (revealjs--beginning-of-slidep)
      (search-backward "<section" nil t))
  (-dotimes (if (revealjs--beginning-of-slidep) (1+ num) num)
            (lambda (n)
                  (if (search-backward "<section" nil t)
                      (revealjs--beginning-of-slide)))))

(defun revealjs--headerp ()
  "Returns t if point is currently within an HTML header"
  (save-excursion
    (sgml-skip-tag-backward 1)
    (looking-at "<h[0-6]")))

(defun revealjs-set-header-level (level)
  "Change the level of the heading on the current line"
  (interactive "P")
  (if (not (revealjs--headerp))
      (progn
        (beginning-of-line)
        (if (search-forward "<h" (save-excursion (end-of-line)) t)
            (search-forward ">" nil t))))
  (if (revealjs--headerp)
      (save-excursion
        (sgml-skip-tag-backward 1)
        (let* ((curlevel (buffer-substring (+ 2 (point)) (+ 3 (point))))
               (target (if level level (1+ (mod (string-to-number curlevel) 6)))))
          (right-char 2)
          (delete-char 1)
          (insert (number-to-string target))
          (search-forward (concat "</h" curlevel))
          (left-char 1)
          (delete-char 1)
          (insert (number-to-string target))))))

(defun revealjs--fragmentp ()
  (save-excursion
    (search-forward "class=\"fragment\"" (save-excursion (search-forward ">")) t)))

(defun revealjs--remove-fragment ()
  (save-excursion
    (search-forward "class=\"fragment\"")
    (delete-backward-char 17)))

(defun revealjs--add-fragment ()
  (save-excursion
    (search-forward ">")
    (left-char 1)
    (insert " class=\"fragment\"")))

(defun revealjs-fragmentize ()
  (interactive)
  (save-excursion
    (sgml-skip-tag-backward 1)
    (if (revealjs--fragmentp)
        (revealjs--remove-fragment)
      (revealjs--add-fragment))))

(defun revealjs-fragmentize-region (rbeginning rend)
  (interactive "r")
  (save-excursion
    ;; WTF's up with having to use progn and point to get the position?
    (let ((beginning (if mark-active rbeginning (progn(beginning-of-line) (point))))
          (end (if mark-active rend (progn (end-of-line) (point)))))
      (goto-char end)
      (insert "</span>")
      (goto-char beginning)
      (insert "<span class=\"fragment\">"))))

(defun revealjs-unfragmentize-region (rbeginning rend)
  (interactive "r")
  (save-excursion
    (let ((beginning (if mark-active rbeginning (progn (beginning-of-line) (point))))
          (end (if mark-active rend (progn (end-of-line) (point)))))
      (goto-char end)
      (if (search-backward "</span>" (- (point) 7) t)
          (delete-char 7))
      (goto-char beginning)
      (if (search-forward "<span class=\"fragment\">" (+ (point) 23) t)
          (delete-backward-char 23)))))

(define-key revealjs-mode-map
  (kbd "M-n") 'revealjs-next-slide)
(define-key revealjs-mode-map
  (kbd "M-p") 'revealjs-previous-slide)
(define-key revealjs-mode-map
  (kbd "M-h") 'revealjs-set-header-level)
(define-key revealjs-mode-map
  (kbd "C-c f") 'revealjs-fragmentize)
(define-key revealjs-mode-map
  (kbd "C-c F") 'revealjs-fragmentize-region)
(define-key revealjs-mode-map
  (kbd "C-c U") 'revealjs-unfragmentize-region)

(define-minor-mode revealjs-mode
  "Org RevealJS mode" nil " rjs" revealjs-mode-map)

(provide 'revealjs-mode)

;;; revealjs-mode.el ends here
