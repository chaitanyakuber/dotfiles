;;; lazy-desktop.el --- Modify desktop to open slowly in the idle-cycle.

;; $Revision: 1.3 $
;; $Date: 2004/06/07 12:39:09 $

;; This file is not part of Emacs

;; Author: Phillip Lord <p.lord@russet.org.uk>
;; Maintainer: Phillip Lord <p.lord@russet.org.uk>
;; Website: http://www.russet.org.uk

;; COPYRIGHT NOTICE
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;; Desktop is a really nice utility.  Your Emacs will open up as it
;; was killed.  I like this.  But this means the total number of open
;; buffers tends to grow large.  Sometimes I kill them all, just for
;; fun.  What a nasty individual I am.
;;
;; lazy-desktop does what you'd expect.  It opens up a couple of files
;; to be starting with.  And then runs everything else in the idle
;; cycle, opening up buffers slowly, hopefully in a way which should
;; not annoy you while working.  This way you get (more or less) the
;; best of both worlds.
;;
;; To get this to work do (require 'lazy-desktop) in your .emacs.
;; Obviously you need to have desktop working as well. You need to do
;; this BEFORE you call `desktop-read', or your emacs will crash when
;; starting up.
;;
;; You can set `lazy-desktop-verbose' if you want it to open buffers
;; in a way which will annoy you while working.

;;; Status:
;; 
;; I have just written this. It needs tidying up, and some things need
;; making options and so forth. 
;;
;; Currently only tested on Emacs.

;;; Bugs:
;;
;; Currently interacts really badly with ECB. 
;; If the desktop hasn't fully loaded, it will be lost when Emacs is
;; shut down. 

;;; History:
;; 

;;; Code:
(defgroup lazy-desktop nil
  "Restore status of Emacs in the idle cycle after starting"
  :group 'frames)

(defcustom lazy-desktop-verbose nil
  "Verbose reporting of lazy-desktop load"
  :group 'lazy-desktop
  :type 'boolean)

(defcustom lazy-desktop-idle-delay 5
  "Idle delay before starting to load desktop"
  :group 'lazy-desktop
  :type 'integer)


;; change the default form so that this file is called for opening the
;; buffer

(setq desktop-create-buffer-form "(lazy-desktop-create-buffer 205")

(defvar lazy-desktop-create-buffer-stack nil
  "A stack created to store the loaded files.")

(defun lazy-desktop-create-buffer (ver desktop-buffer-file-name desktop-buffer-name
                                       desktop-buffer-major-mode
                                       mim pt mk ro desktop-buffer-misc
                                       &optional locals)
  "Despite the name don't create a buffer, but store knowledge of it, so we can do so later.
I don't know what all the parameters are going to do. So I will not document them, even if 
`checkdoc' tells me to."
  (push
   ;; what a lot of parameters!
   (list ver desktop-buffer-file-name desktop-buffer-name
         desktop-buffer-major-mode
         mim pt mk ro desktop-buffer-misc
         locals)
   lazy-desktop-create-buffer-stack))

(add-hook 'desktop-delay-hook 'lazy-desktop-delay)

(defvar lazy-desktop-timer nil)

(defun lazy-desktop-delay()
  "Open some buffers, set timers running"
  (let ((open-buffer))
    ;; open some buffers. The first one is the one we want to select.
    (lazy-desktop-open-next-buffer)
    (setq open-buffer (current-buffer))
    (lazy-desktop-open-next-buffer)
    (lazy-desktop-open-next-buffer)
    (switch-to-buffer open-buffer)
    ;; now set up a timer to be going on with.
    (setq lazy-desktop-timer
          (run-with-idle-timer 5 t 'lazy-desktop-idle-timer))))

(defun lazy-desktop-idle-timer()
  "Loop run in idle.
Open up some more buffers, until the user does something, then stop.
If there are no buffers left to open, then stop, kill the timer,
and thats it."
  (let ((repeat 1))
    (while (and repeat lazy-desktop-create-buffer-stack)
      (save-window-excursion
        (lazy-desktop-open-next-buffer))
      (setq repeat (sit-for 0.2)))
    (unless lazy-desktop-create-buffer-stack
      (message "Lazy desktop load complete")
      (sit-for 3)
      (message "")
      (cancel-timer lazy-desktop-timer))))

(defun lazy-desktop-open-next-buffer()
  "Open a buffer, and bury it"
  (when lazy-desktop-create-buffer-stack
    (let* ((remaining (length lazy-desktop-create-buffer-stack))
           (buffer
            (pop lazy-desktop-create-buffer-stack))
           (buffer-name (nth 2 buffer)))
      (if lazy-desktop-verbose
          (message "Lazily opening %s (%s remaining)..." buffer-name remaining))
      (apply 'desktop-create-buffer buffer)
      (bury-buffer (get-buffer buffer-name))
      (if lazy-desktop-verbose
          (message "Lazily opening %s (%s remaining)...done" buffer-name remaining)))))
    
(defun lazy-desktop-complete()
  "Run the desktop load to completion"
  (interactive)
 (let ((lazy-desktop-verbose t))
    (while lazy-desktop-create-buffer-stack
      (save-window-excursion
        (lazy-desktop-open-next-buffer)))
    (message "Lazy desktop load complete")))

(provide 'lazy-desktop)
;;; lazy-desktop.el ends here
