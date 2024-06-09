#!/bin/bash

prepare_package() {
  sudo apt-get install autoconf patch build-essential \
    rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev \
    libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev \
    libdb-dev uuid-dev
}

prepare_package
