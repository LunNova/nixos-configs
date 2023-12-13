_:
{
  config = {
    security.audit.enable = false;
    boot.kernelParams = [ "audit=0" ];
  };
}
