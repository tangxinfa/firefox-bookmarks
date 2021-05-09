;;; firefox-bookmarks.el --- Complete Firefox bookmarks  -*- lexical-binding: t; -*-

;; Copyright (C) 2015-2018  Free Software Foundation, Inc.

;; Author: tangxinfa <tangxinfa@gmail.com>
;; Keywords: matching

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

;;** `firefox-bookmarks'
(defvar firefox-bookmarks-file
  (car (file-expand-wildcards "~/.mozilla/firefox/*/bookmarks.html"))
  "Firefox's automatically exported HTML bookmarks file.")

(defface firefox-bookmarks-tag
  '((t :inherit font-lock-comment-face))
  "Face used by `firefox-bookmarks' for tags.")

(defface firefox-bookmarks-location
  '((t :inherit link))
  "Face used by `firefox-bookmarks' for locations.")

(declare-function xml-substitute-special "xml")

(defun firefox-bookmarks-candidates ()
  "Return list of `firefox-bookmarks' candidates."
  (unless (and firefox-bookmarks-file
               (file-readable-p firefox-bookmarks-file))
    (signal 'file-error (list "Opening `firefox-bookmarks-file'"
                              "No such readable file"
                              firefox-bookmarks-file)))
  (require 'xml)
  (with-temp-buffer
    (insert-file-contents firefox-bookmarks-file)
    (let ((case-fold-search t)
          candidates)
      (while (re-search-forward
              "<a href=\"\\([^\"]+?\\)\"[^>]*?>\\([^<]*?\\)</a>" nil t)
        (let* ((a (match-string 0))
               (href (match-string 1))
               (name (save-match-data
                       (xml-substitute-special (match-string 2))))
               (tags (and (string-match "tags=\"\\([^\"]+?\\)\"" a)
                          (mapconcat
                           (lambda (tag)
                             (put-text-property 0 (length tag) 'face
                                                'firefox-bookmarks-tag
                                                tag)
                             tag)
                           (split-string (match-string 1 a) "," t)
                           ":"))))
          (put-text-property 0 (length href)
                             'face
                             'firefox-bookmarks-location
                             href)
          (push (mapconcat #'identity
                           (remove nil
                                   (list name
                                         (when tags (concat ":" tags ":"))
                                         (unless (string= name href)
                                           href)))
                           "  ") candidates)))
      candidates)))

;;;###autoload
(defun firefox-bookmarks ()
  "Complete Firefox bookmarks.
This requires HTML bookmark export to be enabled in Firefox.
To do this, open URL `about:config' in Firefox, make sure that
the value of the setting \"browser.bookmarks.autoExportHTML\" is
\"true\" by, say, double-clicking it, and then restart Firefox."
  (interactive)
  (let ((candidate
         (completing-read "bookmark: " (firefox-bookmarks-candidates)
                          nil t nil 'firefox-bookmarks-history)))
    (browse-url (car (last (split-string candidate))))))

(provide 'firefox-bookmarks)
;;; firefox-bookmarks.el ends here
