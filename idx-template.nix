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

    # Move into project directory
    cd "$WS_NAME"

    # Install dependencies and prepare Expo environment
    if [ "${packageManager}" = "pnpm" ]; then
      pnpm install --prefer-offline
      pnpm add @expo/ngrok@^4.1.0
      npx -y expo install expo-dev-client
      npx -y expo prebuild --platform android
      sed -i 's/org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m/org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=512m/' android/gradle.properties
    else
      ${packageManager} install
    fi

    # Prepare IDX configuration folder
    mkdir -p ".idx"

    # Render dev.nix from Jinja template
    packageManager=${packageManager} j2 ${./devnix.j2} -o ".idx/dev.nix"

    # Render README.md from Jinja template
    packageManager=${packageManager} j2 ${./README.j2} -o "README.md"

    # Set permissions
    chmod -R +w .

    # Move workspace to output
    mv . "$out"

    # Copy additional IDX files
    mkdir -p "$out/.idx"
    chmod -R u+w "$out"
    cp -rf ${./.idx/airules.md} "$out/.idx/airules.md"
    cp -rf "$out/.idx/airules.md" "$out/GEMINI.md"
    chmod -R u+w "$out"
  '';
}
