#!/bin/bash

prepare_package() {
  sudo apt-get install -y git-core curl zlib1g-dev build-essential \
    libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 \
    libxml2-dev libxslt1-dev libcurl4-openssl-dev \
    software-properties-common libffi-dev rustc
}

prepare_package
