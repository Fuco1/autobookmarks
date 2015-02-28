;;; autobookmarks.el --- Save recently visited files and buffers

;; Copyright (C) 2015 Matúš Goljer <matus.goljer@gmail.com>

;; Author: Matúš Goljer <matus.goljer@gmail.com>
;; Maintainer: Matúš Goljer <matus.goljer@gmail.com>
;; Version: 0.0.1
;; Created: 14th February 2014
;; Package-requires: ((dash "2.10.0"))
;; Keywords: files

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'dash)

(defgroup autobookmarks ()
  "Save recently visited files and buffers."
  :group 'files
  :prefix "abm-")

(defcustom abm-file "~/.emacs.d/autobookmarks"
  "File where the bookmark data is persisted."
  :type 'file
  :group 'autobookmarks)

(defvar abm-visited-buffers nil
  "List of visited buffers.

A buffer is added to this list as soon as it is visited.

In case the session crashes, it is used to recover the recent
buffer list.")

(defun abm-visited-buffers () abm-visited-buffers)

(defvar abm-recent-buffers nil
  "List of recent buffers.

A buffer is added to this list as soon as it is closed.")

(defun abm-recent-buffers () abm-recent-buffers)

(defcustom abm-visited-buffer-hooks '((find-file-hook . abm-handle-opened-file)
                                      (write-file-functions . abm-handle-opened-file)
                                      (dired-mode-hook . abm-handle-opened-directory))
  "Hooks used to detect visited buffers."
  :type '(repeat
          (cons
           (symbol :tag "Hook")
           (function :tag "Function")))
  :group 'autobookmarks)

(defcustom abm-killed-buffer-functions '(
                                         abm-handle-killed-file
                                         abm-handle-killed-directory
                                         )
  "Functions used to handle killed buffers.

Function should return non-nil if it handled the buffer."
  :type 'hook
  :group 'autobookmarks)

(defcustom abm-restore-buffer-functions '(
                                          abm-restore-file
                                          abm-restore-directory
                                          )
  "Functions used to restore killed buffers.

Function should return non-nil if it restored the buffer."
  :type 'hook
  :group 'autobookmarks)


(defun abm-save-to-file ()
  (interactive)
  (with-temp-file abm-file
    (insert ";; This file is created automatically by autobookmarks.el\n\n")
    (insert (format "(setq abm-visited-buffers '%S)\n" abm-visited-buffers))
    (insert (format "(setq abm-recent-buffers '%S)" abm-recent-buffers))))

(defun abm-load-from-file ()
  (interactive)
  (load-file abm-file)
  (setq abm-recent-buffers (-concat abm-recent-buffers abm-visited-buffers))
  (setq abm-visited-buffers nil))

(defun abm-handle-opened-file ()
  "Handle opened file buffer"
  (let ((file (buffer-file-name)))
    (unless (assoc file abm-visited-buffers)
      (push (cons file (list :type :file)) abm-visited-buffers))
    (setq abm-recent-buffers
          (--remove (and (equal (car it) file)
                         (eq (plist-get (cdr it) :type) :file))
                    abm-recent-buffers)))
  (abm-save-to-file))

(defun abm-handle-killed-file ()
  (when (buffer-file-name)
    (let ((file (buffer-file-name)))
      (unless (assoc file abm-recent-buffers)
        (push (cons file (list :type :file)) abm-recent-buffers))
      (setq abm-visited-buffers
            (--remove (and (equal (car it) file)
                           (eq (plist-get (cdr it) :type) :file))
                      abm-visited-buffers)))
    t))

(defun abm-restore-file (entry)
  (-let (((file &keys :type type) entry))
    (when (eq type :file)
      (find-file file)
      t)))

(defun abm-handle-opened-directory ()
  (let ((dir (file-truename default-directory)))
    (unless (assoc dir abm-visited-buffers)
      (push (cons dir (list :type :dired)) abm-visited-buffers))
    (setq abm-recent-buffers
          (--remove (and (equal (car it) dir)
                         (eq (plist-get (cdr it) :type) :dired))
                    abm-recent-buffers)))
  (abm-save-to-file))

(defun abm-handle-killed-directory ()
  (when (eq major-mode 'dired-mode)
    (let ((dir (file-truename default-directory)))
      (unless (assoc dir abm-recent-buffers)
        (push (cons dir (list :type :dired)) abm-recent-buffers))
      (setq abm-visited-buffers
            (--remove (and (equal (car it) dir)
                           (eq (plist-get (cdr it) :type) :dired))
                      abm-visited-buffers)))
    t))

(defun abm-restore-directory (entry)
  (-let (((dir &keys :type type) entry))
    (when (eq type :dired)
      (find-file dir)
      t)))

(defun abm-handle-killed-buffer ()
  (unless (equal " " (substring (buffer-name) 0 1))
    (run-hook-with-args-until-success 'abm-killed-buffer-functions)
    (abm-save-to-file)))

(defun abm-restore-killed-buffer (entry)
  (run-hook-with-args-until-success 'abm-restore-buffer-functions entry))

(define-minor-mode autobookmarks-mode
  "Autobookmarks."
  :group 'autobookmarks
  (if autobookmarks-mode
      (progn
        (add-hook 'kill-emacs-hook 'abm-save-to-file)
        (--each abm-visited-buffer-hooks
          (add-hook (car it) (cdr it)))
        (add-hook 'kill-buffer-hook 'abm-track-killed-buffer))
    (remove-hook 'kill-emacs-hook 'abm-save-to-file)
    (--each abm-visited-buffer-hooks
      (remove-hook (car it) (cdr it)))
    (remove-hook 'kill-buffer-hook 'abm-track-killed-buffer)))

(provide 'autobookmarks)
;;; autobookmarks.el ends here
