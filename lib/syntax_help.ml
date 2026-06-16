(* Short local help shown when Ask is run without a prompt. *)

let text =
  String.concat "\n"
    [
      "Usage: ask [OPTIONS] MESSAGE...";
      "";
      "Examples:";
      "  ask why is my dune build failing?";
      "  ask --verb do --cwd . add a focused regression test";
      "  ask explain --why this flag-looking text is still prompt text";
      "  git diff | ask summarize this patch";
      "";
      "Run `ask --help` for all options.";
    ]

let print channel = output_string channel (text ^ "\n")
