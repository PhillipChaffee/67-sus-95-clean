# Cargo deny covers four

cargo-deny covers four audit categories in one tool: advisories  (RustSec), license compliance, dependency bans, and duplicate versions. One config file, but the README must present them as separate gates with separate CI steps so failures name the gate.
