# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
{ stdenv, fetchFromGitHub, writeText, ... }:
stdenv.mkDerivation rec {
  pname = "s2n_bignum";
  version = "672fbb95cd93021f575c5ee1f86e8f9d3a105287";
  src = fetchFromGitHub {
    owner = "jakemas";
    repo = "s2n-bignum";
    rev = "${version}";
    hash = "sha256-lHlyi1jVbv9k8L4PRs3YRcW8x6J1mysESRmIx3XWM9c=";
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
