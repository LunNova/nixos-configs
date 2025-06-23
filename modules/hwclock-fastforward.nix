{ config, pkgs, lib, ... }:
let
  hwclock = lib.getExe' pkgs.util-linux.bin "hwclock";
  tzFlag = if config.time.hardwareClockInLocalTime then "--localtime" else "--utc";
in
{
  systemd.services.hwclock-fastforward = {
    description = "Fast forwad time to at least 2025, load from hwclock";
    wantedBy = [ "sysinit.target" ];
    after = [ "systemd-modules-load.service" ];
    before = [ "timesyncd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "hwclock-fastforward" ''
        # Try to set a reasonable time at boot if system time looks bad
        CURRENT_YEAR=$(date +%Y)
        if [ "$CURRENT_YEAR" -lt "2025" ]; then
          ${hwclock} -r || true
          ${hwclock} --hctosys ${tzFlag} || true
          if [ "$CURRENT_YEAR" -lt "2025" ]; then
            echo "System time before 2025 detected (current time: $(date))"
            echo "Setting time to 2025-01-01 as fallback"
            date -s "2025-01-01 00:00:00"
            ${hwclock} --systohc ${tzFlag} || true
            echo "Time set to: $(date)"
          fi
        fi
      '';
      RemainAfterExit = true;
    };
  };
  systemd.services.save-hwclock = {
    description = "Sync RTC with hwclock --systohc on shutdown";

    wantedBy = [ "shutdown.target" ];

    unitConfig = {
      DefaultDependencies = false;
      ConditionPathExists = "/dev/rtc";
    };

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${hwclock} --systohc ${tzFlag}";
    };
  };

}
