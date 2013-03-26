Introduction
============

Basically, running-life is a note taking plugin for Emacs, but also
provide a `pomodoro <http://www.pomodorotechnique.com>`_ timer.

When starting a new pomodoro, running-life will automatically insert
text into attached buffer, so that you can write some plan for this
pomodoro. Additional notes can be added during or after this pomodoro.

The idea is very simple, but can have a huge impact on your time and
task management. Just have a try! :)

Installation
============

Put ``runing-life.el`` into your load path, and then do some
customization::

  (add-to-list 'load-path "/path/to/running-life/")

  (require 'running-life)

  ;; Sound file to be played when starting or finishing pomodoros.
  (setq running-life-start-sound "/path/to/a.wav")
  (setq running-life-finish-sound "/path/to/another.wav")

  ;; Text to insert when starting a new pomodoro, it will be passed to
  ;; `format-time-string`.
  (setq running-life-auto-insert-text "%Y/%m/%d %H:%M\n----------------\n\n")

Usage
=====

After installation and configuration, open a file which note will be
stored in, an then run ``running-life-start``, that's all!

Life is short, and time is rapid, so we should running, to catch up
with it. :)
