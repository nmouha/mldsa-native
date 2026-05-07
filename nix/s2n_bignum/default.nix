# Copyright (c) The mlkem-native project authors
# Copyright (c) The mldsa-native project authors
# SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT
{ stdenv, fetchFromGitHub, writeText, ... }:
stdenv.mkDerivation rec {
  pname = "s2n_bignum";
  # Pinned to https://github.com/awslabs/s2n-bignum/pull/387 head,
  # which adds VMOVMSKPS, VPMOVZXBD, and VZEROUPPER instruction models
  # required by the x86_64 rej_uniform proof.
  version = "4c4fe1dfc8b79720013517a7b4dec9014c85fcf2";
  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "s2n-bignum";
    rev = "${version}";
    hash = "sha256-64MJOqoDunpn6fx1j9P4+fDoRNZ8GRTB/d4C2JWvxFA=";
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
