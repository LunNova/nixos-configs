_:
_final: prev:
{
  cosmic-comp = prev.cosmic-comp.overrideAttrs {
    # dontStrip = true;
    # separateDebugInfo = false;
    # env.CARGO_PROFILE_RELEASE_DEBUG = "true";
    env.CARGO_PROFILE_RELEASE_LTO = "fat";
    env.CARGO_PROFILE_RELEASE_INCREMENTAL = "false";
    env.CARGO_PROFILE_RELEASE_CODEGEN_UNITS = 1;
    env.NIX_RUSTFLAGS = "-C target-cpu=znver3";
    # env.CARGO_PROFILE_SPLIT_DEBUGINFO = "none";
    # env.CARGO_PROFILE_RELEASE_STRIP = "none";
    # env.CARGO_CFG_TARGET_FEATURE="fxsr,mmx,sse,avx,avx2,sse2,sse4.1,rdrand,popcnt,fma,movbe,aes,xsave,pclmul,sse4.2,fsgsbase,f16c,bmi,bmi2,lzcnt,hle,rdseed,prefetchw,adcx,xsavec,xsaves";
  };
}
