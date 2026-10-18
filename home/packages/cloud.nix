{
  pkgs,
  awscli2Package ? pkgs.awscli2,
  ...
}:
{
  home.packages = [
    awscli2Package
    (pkgs.azure-cli.withExtensions [ pkgs.azure-cli.extensions.azure-devops ])
    pkgs.google-cloud-sdk
  ];
}
