
{ pkgs, packageManager ? "npm", ... }: {
  packages = [
    pkgs.nodejs_20
    pkgs.yarn
    pkgs.nodePackages.pnpm
    pkgs.bun
    pkgs.j2cli
    pkgs.nixfmt
  ];

  bootstrap = ''
    # Create workspace directory
    mkdir -p "$WS_NAME"

    # Create Expo project using selected package manager
    ${
      if packageManager == "pnpm" then "pnpm create expo \"$WS_NAME\" --no-install"
      else if packageManager == "bun" then "bun create expo \"$WS_NAME\" --no-install"
      else if packageManager == "yarn" then "yarn create expo \"$WS_NAME\" --no-install"
      else "npm create expo \"$WS_NAME\" --no-install"
    }

    # Prepare IDX configuration folder
    mkdir -p "$WS_NAME/.idx/"

    # Render dev.nix from Jinja template
    packageManager=${packageManager} j2 ${./devNix.j2} -o "$WS_NAME/.idx/dev.nix"

    # Render README.md from Jinja template
    packageManager=${packageManager} j2 ${./README.j2} -o "$WS_NAME/README.md"

    # Set permissions
    chmod -R +w "$WS_NAME"

    # Move workspace to output
    mv "$WS_NAME" "$out"

    # Copy additional IDX files
    mkdir -p "$out/.idx"
    chmod -R u+w "$out"
    cp -rf ${./.idx/airules.md} "$out/.idx/airules.md"
    cp -rf "$out/.idx/airules.md" "$out/GEMINI.md"
    chmod -R u+w "$out"
  '';
}
