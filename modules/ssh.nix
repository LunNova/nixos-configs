{
  programs.ssh.extraConfig = ''
    Host *
      ControlMaster auto
      ControlPath ~/.ssh/master-%C
      ControlPersist 2m
  '';
  services.openssh.settings.MaxSessions = 50;
}
