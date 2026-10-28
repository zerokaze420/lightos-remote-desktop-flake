{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchNpmDeps,
  stdenvNoCC,
  stdenv,
  npmHooks,
  nodejs_24,
  pkg-config,
  cmake,
  nasm,
  llvmPackages,
  wayland,
  libxkbcommon,
  libpulseaudio,
  libjpeg_turbo,
  pipewire,
}:
let
  spaSdk = stdenvNoCC.mkDerivation {
    pname = "lightos-spa-headers";
    inherit (pipewire) version src;
    unpackPhase = "true";
    installPhase = ''
      mkdir -p "$out/include/spa-0.2" "$out/lib/pkgconfig"
      cp -r "$src/spa/include/spa" "$out/include/spa-0.2/"
      cat > "$out/lib/pkgconfig/libspa-0.2.pc" <<EOF
      prefix=$out
      Name: libspa-0.2
      Description: SPA headers from the matching PipeWire source
      Version: $version
      Cflags: -I''${prefix}/include/spa-0.2
      EOF
      install -Dm644 "$src/COPYING" "$out/share/licenses/lightos-spa-headers/COPYING"
      test -s "$out/include/spa-0.2/spa/buffer/meta.h"
    '';
    dontFixup = true;
  };
in

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "lightos-remoted";
  version = "0.1.21";

  src = fetchFromGitHub {
    owner = "ca-x";
    repo = "lightos-remote-desktop";
    rev = "v${finalAttrs.version}";
    hash = "sha256-u5UxIy8aNxJVzGfrkUSJJxZ30GEsz/Rkt7SzWJiCkC8=";
  };

  cargoHash = "sha256-eAEi33yFX5v8K7r7uCm7s80wFKGECuOjIXwjCuyx2FU=";
  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    hash = "sha256-59yvapJFNo0BOnwTbZNA+e8M0n+2XVqrGuK6EGkOxOo=";
  };

  nativeBuildInputs = [
    nodejs_24
    npmHooks.npmConfigHook
    pkg-config
    cmake
    nasm
    llvmPackages.libclang
  ];

  buildInputs = [
    wayland
    libxkbcommon
    libpulseaudio
    libjpeg_turbo
    pipewire
  ];

  env.LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
  env.BINDGEN_EXTRA_CLANG_ARGS = "-I${stdenv.cc.libc.dev}/include";
  env.PKG_CONFIG_PATH = "${spaSdk}/lib/pkgconfig:${pipewire.dev}/lib/pkgconfig";

  preBuild = ''
    npm run build
  '';

  buildFeatures = [ "bundled-jpeg" "rdp" "portal" ];
  cargoBuildFlags = [ "--bin" "lightos-remoted" ];
  doCheck = false;

  postInstall = ''
    install -Dm644 LICENSE "$out/share/licenses/lightos-remoted/LICENSE"
    install -Dm644 web/dist/NOTICE.frontend.txt "$out/share/licenses/lightos-remoted/NOTICE.frontend.txt"
  '';

  meta = {
    description = "Browser remote desktop host for Linux";
    homepage = "https://github.com/ca-x/lightos-remote-desktop";
    license = lib.licenses.unfreeRedistributable;
    mainProgram = "lightos-remoted";
    platforms = lib.platforms.linux;
  };
})
