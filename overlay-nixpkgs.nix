_:
final: prev:
let inherit (final) lib; in
{
  libsurvive = prev.libsurvive.overrideAttrs (prevAttrs: {
    version = "unstable-2024-05-10"; # after v1.01

    src = prevAttrs.src.override {
      rev = "4fb6d888d0277a8a3ba725e63707434d80ecdb2a";
      hash = "sha256-VGBX1GtojpS6dhPtoI5yyO4uN8XDxl7iHS+Wo1gw6gg=";
    };
  });

  monado = prev.monado.overrideAttrs (prevAttrs: {
    version = "unstable-2025-01-30"; # after v24.0.0

    src = prevAttrs.src.override {

      # main latest
      rev = "848a24aa106758fd6c7afcab6d95880c57dbe450";
      hash = "sha256-+rax9/CG/3y8rLYwGqoWJa4FxH+Z3eREiwhuxDOUzLs=";
      # old
      # rev = "cef70d03ca749225af0de57824270ad708bd828a";
      # hash = "sha256-w48Xb1YI8LIV2exHFSgCaTz2FonXYAa55RqlvfauGvk=";
    };
    patches = lib.lists.filter
      (patch: !(lib.lists.elem patch.url or null [
        "https://gitlab.freedesktop.org/monado/monado/-/commit/9819fb6dd61d2af5b2d993ed37b976760002b055.patch"
      ])) prevAttrs.patches or [ ] ++ [
      ./patches/nvidia_egl_fence_wait.patch
    ];
  });
}
