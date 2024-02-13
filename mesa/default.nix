/*
  thanks to the chaotic-cx LUG for their mesa-git expression, it inspired some of this
  https://github.com/chaotic-cx/nyx/blob/a4e9fa0795880c3330d9f86cab466a7402d6d4f5/pkgs/mesa-git/default.nix

  MIT License

  Copyright (c) 2023 Pedro Henrique Lara Campos <nyx@pedrohlc.com>

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/
let
  directx-headersOverride = pkgs: pkgs.directx-headers.overrideAttrs (new: _: {
    version = "1.611.0";
    src = pkgs.fetchFromGitHub {
      owner = "microsoft";
      repo = "DirectX-Headers";
      rev = "v${new.version}";
      hash = "sha256-HG2Zj8hvsgv8oeSDp1eK+1A5bvFL6oQIh5mMFWOFsvk=";
    };
  });

  mesonOverride = pkgs: pkgs.meson.overrideAttrs (new: old:
    let
      inherit (pkgs) lib;
      badPatches = [
        "https://github.com/mesonbuild/meson/commit/d5252c5d4cf1c1931fef0c1c98dd66c000891d21.patch"
        "007-darwin-case-sensitivity.patch"
      ];
    in
    {
      version = "1.3.1";

      src = pkgs.fetchFromGitHub {
        owner = "mesonbuild";
        repo = "meson";
        rev = "refs/tags/${new.version}";
        hash = "sha256-KNNtHi3jx0MRiOgmluA4ucZJWB2WeIYdApfHuspbCqg=";
      };

      patches = lib.filter (p: !(builtins.elem (baseNameOf p) badPatches) && !(lib.elem (p.url or null) badPatches)) old.patches;
    });

  removePatches = [
    "0001-dri-added-build-dependencies-for-systems-using-non-s.patch"
    "0002-util-Update-util-libdrm.h-stubs-to-allow-loader.c-to.patch"
    "0003-glx-fix-automatic-zink-fallback-loading-between-hw-a.patch"
  ];
  replacePatches = patch:
    {
      "opencl.patch" = ./opencl2.patch;
      "disk_cache-include-dri-driver-path-in-cache-key.patch" = ./disk-cache.patch;
    }.${baseNameOf patch}
      or patch;

  mesaOverride = pkgs:
    let
      inherit (pkgs) lib;

      cargoDeps = {
        proc-macro2 = {
          version = "1.0.70";
          hash = "sha256-OSePu/X7T2Rs5lFpCHf4nRxYEaPUrLJ3AMHLPNt4/Ts=";
        };
        quote = {
          version = "1.0.33";
          hash = "sha256-Umf8pElgKGKKlRYPxCOjPosuavilMCV54yLktSApPK4=";
        };
        syn = {
          version = "2.0.39";
          hash = "sha256-I+eLkPL89F0+hCAyzjLj8tFUW6ZjYnHcvyT6MG2Hvno=";
        };
        unicode-ident = {
          version = "1.0.12";
          hash = "sha256-M1S5rD+uH/Z1XLbbU2g622YWNPZ1V5Qt6k+s6+wP7ks=";
        };
      };

      cargoFetch = crate:
        pkgs.fetchurl {
          url = "https://crates.io/api/v1/crates/${crate}/${cargoDeps.${crate}.version}/download";
          inherit (cargoDeps.${crate}) hash;
        };

      cargoSubproject = crate: ''
        ln -s ${cargoFetch crate} subprojects/packagecache/${crate}-${cargoDeps.${crate}.version}.tar.gz
      '';

      subprojects = lib.concatMapStringsSep "\n" cargoSubproject (lib.attrNames cargoDeps);
      revert26943 = pkgs.fetchpatch {
        url = "https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/26943.diff";
        hash = "sha256-KwIG68mf+aArMlvWBtGJdOFdCn5zTZJG6geWXE7bK44=";
        revert = true;
      };

      revert24386_1 = pkgs.fetchpatch {
        url = "https://gitlab.freedesktop.org/mesa/mesa/-/commit//299f9497758ca5d7278e5aafd210aa91d20dfb4d.patch";
        hash = "sha256-ugrkIqJ/Tndimn6YIQSanLVvQ5qZfp2m6GGStHLt8xg=";
        revert = true;
      };

      revert24386_2 = pkgs.fetchpatch {
        url = "https://gitlab.freedesktop.org/mesa/mesa/-/commit/1e5bc00715ad8acf3dc323278d0d6a24986bb4ae.patch";
        hash = "sha256-i0+sBeU/c8Eo8WA34aJfMLJOxhd7146+t7H6llGwS+g=";
        revert = true;
      };
    in
    (pkgs.mesa.override {
      directx-headers = directx-headersOverride pkgs;
      meson = mesonOverride pkgs;

      # we use the new flag for this
      enablePatentEncumberedCodecs = false;

      vulkanDrivers =
        if pkgs.stdenv.isLinux
        then
          [
            "amd" # AMD (aka RADV)
            "microsoft-experimental" # WSL virtualized GPU (aka DZN/Dozen)
            "swrast" # software renderer (aka Lavapipe)
            "nouveau-experimental" # nvk
          ]
          ++ lib.optionals (pkgs.stdenv.hostPlatform.isAarch -> lib.versionAtLeast pkgs.stdenv.hostPlatform.parsed.cpu.version "6") [
            # QEMU virtualized GPU (aka VirGL)
            # Requires ATOMIC_INT_LOCK_FREE == 2.
            "virtio"
          ]
          ++ lib.optionals pkgs.stdenv.isAarch64 [
            "broadcom" # Broadcom VC5 (Raspberry Pi 4, aka V3D)
            "freedreno" # Qualcomm Adreno (all Qualcomm SoCs)
            "imagination-experimental" # PowerVR Rogue (currently N/A)
            "panfrost" # ARM Mali Midgard and up (T/G series)
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isx86 [
            "intel" # Intel (aka ANV), could work on non-x86 with PCIe cards, but doesn't build
            "intel_hasvk" # Intel Haswell/Broadwell, "legacy" Vulkan driver (https://www.phoronix.com/news/Intel-HasVK-Drop-Dead-Code)
          ]
        else [ "auto" ];
    }).overrideAttrs (_new: old:
      let
        # for some reason this version string won't work with
        # system.replaceRuntimeDependencies /shrug
        actualVersion = "24.0.0-rc1";
      in
      {
        version = "24.0.0";

        src = pkgs.fetchurl {
          urls = [
            "https://archive.mesa3d.org/mesa-${actualVersion}.tar.xz"
            "https://mesa.freedesktop.org/archive/mesa-${actualVersion}.tar.xz"
          ];

          hash = "sha256-hvsZnrrNlztnUjgdbTnyOLg+V749aVeMOCQ1OkCujO4=";
        };

        nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.rustc pkgs.rust-bindgen ];

        patches =
          (builtins.filter (p: !builtins.elem (baseNameOf p) removePatches) (map replacePatches old.patches))
          ++ lib.optionals (!pkgs.stdenv.hostPlatform.is32bit) [
            revert26943
            revert24386_1
            revert24386_2
          ];

        postPatch =
          old.postPatch
          + ''
            mkdir subprojects/packagecache
            ${subprojects}
          '';

        mesonFlags = old.mesonFlags ++ lib.optional (!pkgs.stdenv.hostPlatform.is32bit) "-D video-codecs=all";
      });
in
{
  overlay = _final: prev: {
    mesa = mesaOverride prev;
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (
        _python-final: python-prev: {
          afdko = python-prev.afdko.overridePythonAttrs (_oldAttrs: {
            doCheck = false;
            checkPhase = ''
          '';
            pytestCheckPhase = ''
          '';
          });
        }
      )
    ];
    #directx-headers = directx-headersOverride prev;
  };
}
