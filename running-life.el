;;
;; Copyright (c) 2012, Xin Wang <dram.wang@gmail.com>
;; 
;; All rights reserved.
;; 
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 
;;   Redistributions of source code must retain the above copyright
;;   notice, this list of conditions and the following disclaimer.
;; 
;;   Redistributions in binary form must reproduce the above copyright
;;   notice, this list of conditions and the following disclaimer in
;;   the documentation and/or other materials provided with the
;;   distribution.
;; 
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
;; FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
;; COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
;; INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
;; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
;; STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
;; OF THE POSSIBILITY OF SUCH DAMAGE.

;;
;; running-life.el
;;
;; running-life is a note taking plugin for Emacs combines with pomodoro
;; time management technique.
;;

(defcustom running-life-work-time 25
  "Work time for one pomodoro, in minutes."
  :group 'running-life
  :type 'integer)

(defcustom running-life-short-break-time 5
  "Short break time, in minutes."
  :group 'running-life
  :type 'integer)

(defcustom running-life-long-break-time 15
  "Long break time, in minutes."
  :group 'running-life
  :type 'integer)

(defcustom running-life-long-break-frequency 4
  "Long break frequency."
  :group 'running-life
  :type 'integer)

(defcustom running-life-start-sound nil
  "A wav file to be played when starting a work or break time."
  :group 'running-life
  :type 'string)

(defcustom running-life-finish-sound nil
  "A wav file to be played when finishing a work or break time."
  :group 'running-life
  :type 'string)

(defcustom running-life-text-directory ""
  "Diretory to store text files"
  :group 'running-life
  :type 'string)

(defcustom running-life-auto-insert-text ""
  "Text to be inserted when starting a new pomodoro."
  :group 'running-life
  :type 'string)

(defcustom running-life-global-mode-line t
  "Set to `t` if time counter should be displayed in all buffers' mode line."
  :group 'running-life
  :type 'boolean)

(defvar running-life-buffer nil)
(defvar running-life-mode-line)
(defvar running-life-start-work-at)
(defvar running-life-start-break-at)
(defvar running-life-state 'stopped)
(defvar running-life-pomodoros 0)

(defun running-life-show-dialog (message)
  (x-popup-dialog t `(,message ("OK" . 0) ("Cancel" . nil))))

(defun running-life-play-sound (sound)
  (let ((file (case sound
		(start running-life-start-sound)
		(finish running-life-finish-sound))))
    (if file
	(start-process "running-life" nil "aplay" file))))

(defun running-life-stopped ()
  (setq running-life-mode-line ""))

(defun running-life-delta-time (a b)
  (+ (* (- (car a) (car b)) 65536) (- (cadr a) (cadr b))))

(defun running-life-work-time-passed ()
  (running-life-delta-time (current-time) running-life-start-work-at))

(defun running-life-break-time-passed ()
  (running-life-delta-time (current-time) running-life-start-break-at))

(defun running-life-start-work ()
  (setq running-life-state 'on-work)
  (setq running-life-start-work-at (current-time))
  (running-life-play-sound 'start)
  (switch-to-buffer running-life-buffer)
  (beginning-of-buffer)
  (if (search-forward "----------------" nil -1)
      (previous-line 2))
  (insert (format-time-string running-life-auto-insert-text))
  (previous-line 1)
  (move-end-of-line nil)
  (raise-frame))

(defun switch-or-open-running-life-file ()
  (letrec ((date (calendar-current-date))
	   (month (car date))
	   (year (caddr date))
	   (fpath (concat (file-name-as-directory running-life-text-directory)
			  (format "%d-%02d.txt" year month))))
    (find-file fpath)))

(defun running-life-start ()
  (interactive)
  (switch-or-open-running-life-file)
  (when (not running-life-buffer)
    (setq running-life-buffer (current-buffer))
    (let ((fmt '(:eval running-life-mode-line)))
      (if running-life-global-mode-line
	  (set-default 'mode-line-format (cons fmt mode-line-format))
	(add-to-list 'mode-line-format fmt)))
    (run-with-timer 0 1 'running-life-main-loop))
  (running-life-start-work))

(defun running-life-display-time-at-mode-line (label seconds)
  (setq running-life-mode-line
	(format-time-string (concat label " %M:%S") (list 0 seconds))))

(defun running-life-on-work ()
  (let* ((seconds (running-life-work-time-passed))
	 (left (- (* 60 running-life-work-time) seconds)))
    (if (<= left 0)
	(progn (running-life-play-sound 'finish)
	       (setq running-life-state 'finish-work))
      (running-life-display-time-at-mode-line "W" left))))

(defun running-life-finish-work ()
  (setq running-life-pomodoros (1+ running-life-pomodoros))
  (if (= (running-life-show-dialog "Well done!\nNow you can have a break.") 0)
      (progn
       (setq running-life-state 'on-break)
       (setq running-life-start-break-at (current-time))
       (switch-to-buffer running-life-buffer)
       (running-life-play-sound 'start)
       (raise-frame))
    (setq running-life-state 'stopped)))

(defun running-life-on-break ()
  (let* ((seconds (running-life-break-time-passed))
	 (left (- (* 60 (if (= (% running-life-pomodoros
				  running-life-long-break-frequency)
			       0)
			    running-life-long-break-time
			  running-life-short-break-time))
		  seconds)))
    (if (<= left 0)
	(progn (running-life-play-sound 'finish)
	       (setq running-life-state 'finish-break))
      (running-life-display-time-at-mode-line "B" left))))

(defun running-life-finish-break ()
  (if (= (running-life-show-dialog
	  "Pomodoro finished.\nReady to start a new one?") 0)
      (running-life-start-work)
    (setq running-life-state 'stopped)))

(defun running-life-main-loop ()
  (case running-life-state
	(stopped (running-life-stopped))
	(on-work (running-life-on-work))
	(finish-work (running-life-finish-work))
	(on-break (running-life-on-break))
	(finish-break (running-life-finish-break))))

(provide 'running-life)
