(* Cmdliner command definition for the ask executable. *)

open Cmdliner
open Result_syntax

let parse_enum parser name value =
  match parser value with
  | Ok value -> Ok value
  | Error message -> Error (`Msg (Printf.sprintf "%s: %s" name message))

let provider_converter =
  let parse = parse_enum Domain.Provider.of_string "provider" in
  let print formatter value =
    Format.pp_print_string formatter (Domain.Provider.to_string value)
  in
  Arg.conv (parse, print)

let verb_converter =
  let parse = parse_enum Domain.Verb.of_string "verb" in
  let print formatter value =
    Format.pp_print_string formatter (Domain.Verb.to_string value)
  in
  Arg.conv (parse, print)

let sandbox_converter =
  let parse = parse_enum Domain.Sandbox.of_string "sandbox" in
  let print formatter value =
    Format.pp_print_string formatter (Domain.Sandbox.to_string value)
  in
  Arg.conv (parse, print)

let color_converter =
  let parse = parse_enum Domain.Color.of_string "color" in
  let print formatter value =
    Format.pp_print_string formatter (Domain.Color.to_string value)
  in
  Arg.conv (parse, print)

let reasoning_effort_converter =
  let parse = parse_enum Domain.Reasoning_effort.of_string "reasoning effort" in
  let print formatter value =
    Format.pp_print_string formatter (Domain.Reasoning_effort.to_string value)
  in
  Arg.conv (parse, print)

let config_path_term =
  let doc =
    "Read configuration from $(docv). Defaults to ASK_CONFIG, then \
     XDG_CONFIG_HOME/ask/config.yaml, then ~/.config/ask/config.yaml when \
     present."
  in
  Arg.(value & opt (some file) None & info [ "config" ] ~docv:"FILE" ~doc)

let provider_term =
  let doc =
    "Agent provider to use. Currently only $(b,codex) is implemented."
  in
  Arg.(
    value
    & opt (some provider_converter) None
    & info [ "provider" ] ~docv:"PROVIDER" ~doc)

let codex_binary_term =
  let doc = "Codex executable to run." in
  Arg.(
    value & opt (some string) None & info [ "codex-binary" ] ~docv:"PATH" ~doc)

let verb_term =
  let doc =
    "Intent for the run: $(b,ask) for normal one-shot use, $(b,do) for an \
     agentic task with workspace-write sandbox by default, $(b,review) for \
     codex exec review --uncommitted, or $(b,raw) for plain codex exec."
  in
  Arg.(
    value
    & opt (some verb_converter) None
    & info [ "verb"; "as" ] ~docv:"VERB" ~doc)

let model_term =
  let doc = "Override the Codex model for this invocation." in
  Arg.(
    value & opt (some string) None & info [ "m"; "model" ] ~docv:"MODEL" ~doc)

let reasoning_effort_term =
  let doc =
    "Override Codex reasoning effort: minimal, low, medium, high, or xhigh."
  in
  Arg.(
    value
    & opt (some reasoning_effort_converter) None
    & info [ "reasoning-effort"; "effort" ] ~docv:"EFFORT" ~doc)

let profile_term =
  let doc = "Use a Codex config profile." in
  Arg.(
    value
    & opt (some string) None
    & info [ "p"; "profile" ] ~docv:"PROFILE" ~doc)

let cwd_term =
  let doc = "Run Codex with $(docv) as its working directory." in
  Arg.(value & opt (some dir) None & info [ "C"; "cwd" ] ~docv:"DIR" ~doc)

let sandbox_term =
  let doc =
    "Codex sandbox mode: read-only, workspace-write, or danger-full-access."
  in
  Arg.(
    value
    & opt (some sandbox_converter) None
    & info [ "s"; "sandbox" ] ~docv:"MODE" ~doc)

let search_term =
  let doc =
    "Enable live web search for Codex by passing the web_search config \
     override."
  in
  let no_doc = "Disable live web search, overriding config." in
  Arg.(
    value
    & vflag None
        [
          (Some true, info [ "search" ] ~doc);
          (Some false, info [ "no-search" ] ~doc:no_doc);
        ])

let ephemeral_term =
  let doc =
    "Persist the Codex session instead of using Ask's ephemeral default."
  in
  let ephemeral_doc = "Force an ephemeral Codex run, overriding config." in
  Arg.(
    value
    & vflag None
        [
          (Some false, info [ "save-session" ] ~doc);
          (Some true, info [ "ephemeral" ] ~doc:ephemeral_doc);
        ])

let git_check_term =
  let skip_doc = "Allow read-only Ask runs outside a Git repository." in
  let require_doc = "Require Codex's Git repository safety check." in
  Arg.(
    value
    & vflag None
        [
          (Some true, info [ "skip-git-check" ] ~doc:skip_doc);
          (Some false, info [ "require-git-repo" ] ~doc:require_doc);
        ])

let color_term =
  let doc = "Codex color mode: always, never, or auto." in
  Arg.(
    value & opt (some color_converter) None & info [ "color" ] ~docv:"WHEN" ~doc)

let images_term =
  let doc = "Attach an image to the initial Codex prompt. Can be repeated." in
  Arg.(value & opt_all file [] & info [ "i"; "image" ] ~docv:"FILE" ~doc)

let json_term =
  let doc = "Emit Codex JSONL events instead of the final message only." in
  Arg.(value & flag & info [ "json" ] ~doc)

let dry_run_term =
  let doc = "Print the Codex command Ask would run, without running it." in
  Arg.(value & flag & info [ "dry-run" ] ~doc)

let load_config explicit_path =
  match explicit_path with
  | Some path -> Config.read_file path
  | None -> Config.read_first_existing (Paths.default_config_paths ())

let execute overrides =
  match overrides.Request.message_words with
  | [] ->
      Syntax_help.print stdout;
      Ok 0
  | _ ->
      let* config = load_config overrides.Request.config_path in
      let request = Request.resolve config overrides in
      let* command = Codex_command.build request in
      if request.dry_run then (
        print_endline (Codex_command.to_shell command);
        Ok 0)
      else Ok (Runner.run command)

let command_term message_words =
  let make config_path provider codex_binary verb model reasoning_effort profile
      cwd sandbox search ephemeral skip_git_repo_check color images json dry_run
      =
    let overrides =
      {
        Request.config_path;
        provider;
        codex_binary;
        verb;
        model;
        reasoning_effort;
        profile;
        cwd;
        sandbox;
        search;
        ephemeral;
        skip_git_repo_check;
        color;
        images;
        json;
        dry_run;
        message_words;
      }
    in
    match execute overrides with
    | Ok exit_code -> exit_code
    | Error message ->
        Printf.eprintf "ask: %s\n%!" message;
        2
  in
  Term.(
    const make $ config_path_term $ provider_term $ codex_binary_term
    $ verb_term $ model_term $ reasoning_effort_term $ profile_term $ cwd_term
    $ sandbox_term $ search_term $ ephemeral_term $ git_check_term $ color_term
    $ images_term $ json_term $ dry_run_term)

let info =
  let doc = "run a one-shot Codex prompt from plain English" in
  let man =
    [
      `S Manpage.s_description;
      `P
        "Ask is a small wrapper around codex exec. The default command is \
         intentionally terse: $(b,ask explain dune files).";
      `P
        "Ask treats the first non-option token as the beginning of the prompt. \
         Everything after that token is prompt text, even if it looks like an \
         option.";
      `P
        "Configuration is YAML at ~/.config/ask/config.yaml by default. \
         Command line options override configuration file values.";
      `S "CONFIGURATION";
      `Pre
        {|provider: codex
codex_binary: codex
default_verb: ask
model: gpt-5.4
reasoning_effort: medium
profile: null
cwd: null
sandbox: null
search: false
ephemeral: true
skip_git_repo_check: null
color: auto
codex_extra_args: []|};
      `S Manpage.s_examples;
      `P "$(b,ask) why is my dune build failing?";
      `P "$(b,ask --verb do --cwd .) add a focused regression test";
      `P "$(b,ask --verb review) focus on CLI argument parsing risks";
      `P "$(b,git diff | ask) summarize this patch";
    ]
  in
  Cmd.info "ask" ~version:"0.1.0" ~doc ~man

let cmd message_words = Cmd.v info (command_term message_words)

let run () =
  let boundary = Argument_boundary.split Sys.argv in
  Cmd.eval' ~argv:boundary.option_argv (cmd boundary.message_words)
