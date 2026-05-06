# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
{ stdenv, fetchFromGitHub, writeText, ... }:
stdenv.mkDerivation rec {
  pname = "s2n_bignum";
  version = "d217ff63806bf3cd8e29461d6871d574d4ce7348";
  src = fetchFromGitHub {
    owner = "jakemas";
    repo = "s2n-bignum";
    rev = "${version}";
    hash = "sha256-R3Gs8UD3DXrDNEGx1L1MKDs5NnW13qRYRgb1UVranPM=";
  };
  setupHook = writeText "setup-hook.sh" ''
    export S2N_BIGNUM_DIR="$1"
  '';
  patches = [ ];
  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -a . $out/
  '';
}
