#!/usr/bin/env bash

sudo mkdir -p ~sddm/.local/share/kscreen/
sudo cp -r ~/.local/share/kscreen/* ~sddm/.local/share/kscreen/
sudo chown -R sddm:sddm ~sddm
sudo ls ~sddm/.local/share/kscreen/ -l
