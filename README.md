# LightOS Remote Desktop Nix flake

This flake builds [LightOS Remote Desktop](https://github.com/ca-x/lightos-remote-desktop)
from the pinned upstream `v0.1.21` source. It builds the locked web frontend first,
then the Rust host with upstream's release features: `bundled-jpeg,rdp,portal`.

The upstream software uses the PolyForm Noncommercial 1.0.0 license. Nix marks
the package unfree, so permit this package when building:

```sh
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#lightos-remoted
NIXPKGS_ALLOW_UNFREE=1 nix run --impure . -- --help
```

The output includes the `lightos-remoted` executable and license notices. It
does not install a system service or provision a desktop. See the upstream
[installation guide](https://github.com/ca-x/lightos-remote-desktop/blob/v0.1.21/docs/install.md)
for host configuration and runtime requirements. NixOS users should configure
the service declaratively instead of running the upstream `install-service`
command, which targets conventional `/usr` and `/etc` paths.
