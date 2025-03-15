#!/bin/bash

configure_package() {
  git config --global alias.ch checkout
  git config --global alias.cm commit
  git config --global alias.cmm 'commit -m'
  git config --global alias.cb 'checkout -b'
  git config --global alias.st status
  git config --global alias.pl pull
  git config --global alias.ps push
  git config --global alias.undo 'reset HEAD~1'
  git config --global alias.rs reset
  git config --global alias.hrs 'reset --hard'
  git config --global alias.fps 'push --force'
  git config --global core.editor vim
}

install_package git
configure_package
