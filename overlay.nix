{ flake-args }:
final: prev:
let
  inherit (flake-args) self;
  localPackages = self.localPackagesForPkgs final;
  enableKwinFt = false;
in
{
  lun = localPackages;
  powercord-plugins = self.lib.filterPrefix "pcp-" flake-args;
  powercord-themes = self.lib.filterPrefix "pct-" flake-args;
  inherit (localPackages) kwinft;
  nix-gaming = flake-args.nix-gaming.packages.${final.system};
  # gst-plugins-bad pulls in opencv which we don't want
  # TODO: upstream option for this
  # gst_all_1 = (prev.gst_all_1 // {
  #   gst-plugins-bad = (prev.gst_all_1.gst-plugins-bad.override {
  #     opencv4 = prev.emptyDirectory;
  #   }).overrideAttrs
  #     (prev: {
  #       mesonFlags = prev.mesonFlags ++ [ "-Dopencv=disabled" ];
  #     });
  # });
  # FIXME: kwin tearing patch results in no display
  # plasma5Packages = prev.plasma5Packages.overrideScope' (_self2: super2: {
  #   plasma5 = super2.plasma5.overrideScope' (_self1: super1: {
  #     inherit (prev.plasma5Packages.plasma5) plasma-workspace;
  #     kwin = super1.kwin.overrideAttrs (old: {
  #       # src = pkgs.fetchFromGitLab {
  #       #   domain = "invent.kde.org";
  #       #   owner = "plasma";
  #       #   repo = "kwin";
  #       #   rev = "f7648611573a893dc0f4a8d3ad7ed80e1ff82749";
  #       #   sha256 = "sha256-OkLi3nU1iBuELffC4I97TvsFkws3ihTHNeo2gVbQfN8=";
  #       # };
  #       patches = (old.patches or []) ++ [
  #         ./packages/kwin/927-tearing.patch
  #        ];
  #     });
  #   });
  # });
} // (self.lib.setIf enableKwinFt {
  plasma5Packages = prev.plasma5Packages.overrideScope' (_self2: super2: {
    plasma5 = super2.plasma5.overrideScope' (_self1: _super1: {
      inherit (localPackages.kwinft) kwin;
      inherit (prev.plasma5Packages.plasma5) plasma-workspace;
    });
  });
  # TODO: can we get disman and kdisplay included just with this toggle
})
