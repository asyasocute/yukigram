let
  # SPDX-SnippetBegin
  # SPDX-SnippetCopyrightText: Contributors to the Sprinkles project
  # SPDX-License-Identifier: MIT OR Apache-2.0
  fix = f: let x = f x; in x;
  fixWithOverride = o: f: (final: let prev = f final; in prev // o final prev);
  toOverride = x:
    if builtins.isFunction x
    then
      final: prev: let
        xWithPrev = x prev;
      in
        if builtins.isFunction xWithPrev
        then x final prev
        else xWithPrev
    else final: prev: x;
  fixOverridableWith = e: f:
    (fix f)
    // e
    // {
      override = o: fixOverridableWith e (fixWithOverride (toOverride o) f);
    };
  fixOverridable = f: fixOverridableWith {} f;
  # SPDX-SnippetEnd
  makeOverridable = func: defargs:
    (func defargs)
    // {
      override = args: makeOverridable func (defargs // args);
    };
in
  {
    sources ? import ./npins,
    system ? builtins.currentSystem,
  }:
    fixOverridable (self: {
      inherit sources;

      inputs = {
        pkgs = import self.sources.nixpkgs {inherit system;};
        nixpak = import self.sources.nixpak;
      };

      packages = {
        default = self.packages.nixpak;
        nonisolated = self.inputs.pkgs.callPackage ./package.nix {};
        nixpak = self.nixpak.yukigram.config.env;
      };

      nixpak.yukigram = makeOverridable (import ./nixpak.nix) {
        inherit (self.inputs) pkgs nixpak;
        yukigram = self.packages.nonisolated;
      };
    })
