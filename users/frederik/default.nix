{ lib, pkgs, ... }:
let
  fullName = "Frederik Engels";
in
{
  users.mutableUsers = false;
  users.users.frederik = {
    isNormalUser = true;
    hashedPassword = "$6$wogUsyO4$qwcGdg4U0w4sO3sdUKnuwl9Na0rynyB7jKiCJqRWc1I0rbrZwN0OW7mT6YNOK7zFvlSF0z5WSZjffOkOACHsM1";
    home = "/home/frederik";
    description = fullName;
    extraGroups = [ "wheel" "networkmanager" "input" "video" "audio" "adbusers" ];
    shell = pkgs.fish;
  };

  home-manager.users.frederik = {
    programs.git = {
      enable = true;
      userName = fullName;
      userEmail = "frederik.engels92@gmail.com";
    };
  };
}