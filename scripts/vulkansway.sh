#!/bin/sh
VK_LAYER_PATH=$(nix eval --raw pkgs#vulkan-validation-layers)/share/vulkan/explicit_layer.d WLR_RENDERER=vulkan \
  nix shell pkgs#vulkan-validation-layers .#sway_1_7 -c sway --unsupported-gpu
