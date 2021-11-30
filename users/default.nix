# https://github.com/MatthewCroughan/nixcfg/blob/d577d164eadc777b91db423e59b4ae8b26853fc6/users/default.nix
self:
{
  lun = {
    imports = [ ./lun ];
    _module.args.inputs = self.inputs;
    _module.args.self = self;
  };
}
