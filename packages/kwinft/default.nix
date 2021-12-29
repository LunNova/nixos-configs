{ pkgs, lib, libsForQt5 }:

lib.makeScope pkgs.newScope (self: with self; {
  disman = libsForQt5.callPackage ./disman { };
  wrapland = libsForQt5.callPackage ./wrapland { };
  kwin = libsForQt5.callPackage ./kwin { };
  kdisplay = libsForQt5.callPackage ./kdisplay { };
})
