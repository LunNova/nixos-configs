_: final: prev:
{
  libratbag = prev.libratbag.overrideAttrs (old: {
    src = final.fetchFromGitHub {
      owner = "libratbag";
      repo = "libratbag";
      rev = "874c01732a7d3c074baefd8055c0d3efe8c9a935";
      hash = "sha256-O9DxwAieUEy+otwDSM2412vCCQJkHIrDOPVYevg0l44=";
    };

    patches = (old.patches or [ ]) ++ [
      ./libratbag-hidraw-asus.patch
    ];
  });
}
