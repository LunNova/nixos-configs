_:
final: prev:
{
  #   libsurvive = prev.libsurvive.overrideAttrs (prevAttrs: {
  #     version = "unstable-2025-04-07"; # after v1.01

  # nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
  #   final.python3
  # ];
  # buildInputs = prevAttrs.buildInputs ++ [
  #   final.python3
  # ];

  #   # https://github.com/cntools/libsurvive/issues/272
  #   postPatch = ''
  #     substituteInPlace survive.pc.in \
  #       libs/cnkalman/cnkalman.pc.in libs/cnmatrix/cnmatrix.pc.in \
  #       --replace '$'{exec_prefix}/@CMAKE_INSTALL_LIBDIR@ @CMAKE_INSTALL_FULL_LIBDIR@
  #   '';

  #     # src = prevAttrs.src.override {
  #     #   rev = "4fb6d888d0277a8a3ba725e63707434d80ecdb2a";
  #     #   hash = "sha256-VGBX1GtojpS6dhPtoI5yyO4uN8XDxl7iHS+Wo1gw6gg=";
  #     # };
  #     src = final.fetchFromGitHub {
  #       owner = "collabora";
  #       repo = "libsurvive";
  #       rev = "32cf62c52744fdc32003ef8169e8b81f6f31526b";
  #       hash = "sha256-PIQW5L0vtaYD2b8wuDAthWS+mDX4cvFELDSUZ7RD4Ac=";
  #     };
  #   });

  opencomposite = prev.opencomposite.overrideAttrs {
    src = final.fetchFromGitLab {
      owner = "znixian";
      repo = "OpenOVR";
      rev = "485023192cc4605c2a140f8255620d77ef129043";
      hash = "sha256-6nd7kolP1CSB5Pgy9NhVcLdlwc9bMLrmqDArOQxvpis=";
      fetchSubmodules = true;
    };
  };

  #   monado = prev.monado.overrideAttrs (prevAttrs: {
  #     version = "25.0";

  #     src = final.fetchFromGitLab {
  #   domain = "gitlab.freedesktop.org";
  #   owner = "monado";
  #   repo = "monado";
  #   rev = "2a6932d46dad9aa957205e8a47ec2baa33041076";
  #   hash = "sha256-Bus9GTNC4+nOSwN8pUsMaFsiXjlpHYioQfBLxbQEF+0=";
  # };
  #     # src = prevAttrs.src.override {

  #     #   # main latest
  #     #   # rev = "848a24aa106758fd6c7afcab6d95880c57dbe450";
  #     #   # hash = "sha256-+rax9/CG/3y8rLYwGqoWJa4FxH+Z3eREiwhuxDOUzLs=";
  #     #   # 25.0
  #     #   rev = "a041c6168332e80cf79698319ab4da533c8eb606";
  #     #   hash = "sha256-VxTxvw+ftqlh3qF5qWxpK1OJsRowkRXu0xEH2bDckUA=";
  #     #   # old
  #     #   # rev = "cef70d03ca749225af0de57824270ad708bd828a";
  #     #   # hash = "sha256-w48Xb1YI8LIV2exHFSgCaTz2FonXYAa55RqlvfauGvk=";
  #     # };
  #     # patches = lib.lists.filter
  #     #   (patch: !(lib.lists.elem patch.url or null [
  #     #     "https://gitlab.freedesktop.org/monado/monado/-/commit/9819fb6dd61d2af5b2d993ed37b976760002b055.patch"
  #     #   ])) prevAttrs.patches or [ ] ++ [
  #     #   # ./patches/nvidia_egl_fence_wait.patch
  #     # ];
  #   });
}
