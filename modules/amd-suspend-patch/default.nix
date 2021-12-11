{
  config.boot.kernelPatches = [
    {
      # platform/x86: amd-pmc: Fix s2idle failures on certain AMD laptops
      # https://lore.kernel.org/all/b5bd85b9-5cbf-0774-3638-cea660159dec@redhat.com/T/
      name = "s2idle-fix";
      patch = ./pmc_msg_delay_min_us.patch;
    }
  ];
}
