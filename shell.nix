{ pkgs ? import <nixpkgs> {} }:

let
  beam = pkgs.beam.packages.erlang_27;
in
pkgs.mkShell {
  name = "elixir-shell";

  buildInputs = [
    beam.erlang
    beam.elixir
    beam.hex
    beam.rebar3
    pkgs.git
  ];

  shellHook = ''
    export MIX_HOME=$PWD/.mix
    export HEX_HOME=$PWD/.hex
    export ERL_LIBS=$PWD/_build/dev/lib
    export PATH=$MIX_HOME/bin:$PATH

    echo "🔧 Elixir environment ready (Erlang ${beam.erlang.version})"
  '';
}
