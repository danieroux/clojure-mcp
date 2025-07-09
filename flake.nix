{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils } @ inputs:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        addToClaudeDesktop = pkgs.writeShellScriptBin "clojure-mcp-dev-add-to-claude" ''
          CLAUDE_DESKTOP_CONFIG_FILE=~/Library/Application\ Support/Claude/claude_desktop_config.json
          [ ! -f "$CLAUDE_DESKTOP_CONFIG_FILE" ] && echo '{}' > "$CLAUDE_DESKTOP_CONFIG_FILE"; jq '.mcpServers."clojure-mcp-dev" = {
              "command": "/bin/sh",
              "args": [
                  "-c",
                  "cd ${builtins.toString ./.} && ${pkgs.clojure}/bin/clojure -X:dev-mcp"
              ]
          }' "$CLAUDE_DESKTOP_CONFIG_FILE" > config_updated.json && mv config_updated.json "$CLAUDE_DESKTOP_CONFIG_FILE"
          echo "Added clojure-mcp-dev to Claude Desktop, restarting should make it show up"
        '';
        repl = pkgs.writeShellScriptBin "repl" ''
          clojure -M:nrepl
        '';

      in
      rec {
        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShellNoCC {
          shellHook = ''
            echo
            echo "All aliases:"
            echo
            ${pkgs.clojure}/bin/clojure -X:deps aliases
            echo 
            echo "Start a repl with:"
            echo
            echo " repl"
            echo 
            echo "Add clojure-mcp-dev to Claude Desktop with:"
            echo
            echo " clojure-mcp-dev-add-to-claude"
            echo 
            echo "(the command is idempotent)"
            echo
          '';

          packages = [ pkgs.clojure repl addToClaudeDesktop ];
        };
      });
}
