# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ # <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/c7745ef1-af0d-4750-9359-aa5ff5477970";
      fsType = "btrfs";
      options = [ "noatime" "nodiratime" ]; # already have offline trim enabled
    };
  services.fstrim.enable = true;

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6D11-8DC2";
      fsType = "vfat";
      options = [ "noatime" "nodiratime" ];
    };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
