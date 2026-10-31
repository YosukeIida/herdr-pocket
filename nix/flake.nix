{
  description = "herdr-pocket dev shell (XcodeGen, bun for mod bundling)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Why not mkShell: it brings nix's apple-sdk and clang wrapper, which hide Xcode's
          # swift and the iOS SDK that every build here needs.
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              xcodegen
              bun
            ];
          };
        }
      );
    };
}
