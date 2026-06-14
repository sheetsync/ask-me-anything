(* Focused unit tests for Ask's config and Codex command translation. *)

module Command = Ask_me_anything.Codex_command
module Config = Ask_me_anything.Config
module Domain = Ask_me_anything.Domain
module Request = Ask_me_anything.Request

let fail message = raise (Failure message)

let assert_equal_string_list expected actual =
  if expected <> actual then
    fail
      (Printf.sprintf "expected [%s], got [%s]"
         (String.concat "; " expected)
         (String.concat "; " actual))

let assert_equal_string expected actual =
  if expected <> actual then
    fail (Printf.sprintf "expected %S, got %S" expected actual)

let assert_ok = function Ok value -> value | Error message -> fail message

let base_request ?(verb = Domain.Verb.Ask) ?sandbox ?(search = false)
    ?(ephemeral = true) ?skip_git_repo_check ?(json = false)
    ?(model = Config.default_model)
    ?(reasoning_effort = Config.default_reasoning_effort) ?prompt () =
  {
    Request.provider = Domain.Provider.Codex;
    codex_binary = "codex";
    verb;
    model;
    reasoning_effort;
    profile = None;
    cwd = None;
    sandbox;
    search;
    ephemeral;
    skip_git_repo_check;
    color = None;
    images = [];
    json;
    dry_run = false;
    prompt;
    codex_extra_args = [];
  }

let codex_command_when_default_ask_provided_builds_codex_exec_command () =
  let request = base_request ~prompt:"explain dune files" () in
  let command = assert_ok (Command.build request) in
  assert_equal_string "codex" command.executable;
  assert_equal_string_list
    [
      "exec";
      "-m";
      "gpt-5.4";
      "--ephemeral";
      "--skip-git-repo-check";
      "-c";
      "model_reasoning_effort=\"medium\"";
      "explain dune files";
    ]
    command.arguments

let codex_command_when_do_verb_without_sandbox_builds_workspace_write_command ()
    =
  let request =
    base_request ~verb:Domain.Verb.Do ~prompt:"add a regression test" ()
  in
  let command = assert_ok (Command.build request) in
  assert_equal_string_list
    [
      "exec";
      "-m";
      "gpt-5.4";
      "-s";
      "workspace-write";
      "--ephemeral";
      "-c";
      "model_reasoning_effort=\"medium\"";
      "add a regression test";
    ]
    command.arguments

let codex_command_when_review_verb_provided_uses_review_subcommand () =
  let request =
    base_request ~verb:Domain.Verb.Review ~prompt:"focus on parser risks" ()
  in
  let command = assert_ok (Command.build request) in
  assert_equal_string_list
    [
      "exec";
      "review";
      "--uncommitted";
      "-m";
      "gpt-5.4";
      "--ephemeral";
      "--skip-git-repo-check";
      "-c";
      "model_reasoning_effort=\"medium\"";
      "focus on parser risks";
    ]
    command.arguments

let codex_command_when_search_enabled_uses_codex_config_override () =
  let request = base_request ~search:true ~prompt:"latest docs?" () in
  let command = assert_ok (Command.build request) in
  assert_equal_string_list
    [
      "exec";
      "-m";
      "gpt-5.4";
      "--ephemeral";
      "--skip-git-repo-check";
      "-c";
      "model_reasoning_effort=\"medium\"";
      "-c";
      "web_search=\"live\"";
      "latest docs?";
    ]
    command.arguments

let codex_command_when_custom_reasoning_effort_provided_builds_config_override
    () =
  let request =
    base_request ~reasoning_effort:Domain.Reasoning_effort.High
      ~prompt:"think a bit harder" ()
  in
  let command = assert_ok (Command.build request) in
  assert_equal_string_list
    [
      "exec";
      "-m";
      "gpt-5.4";
      "--ephemeral";
      "--skip-git-repo-check";
      "-c";
      "model_reasoning_effort=\"high\"";
      "think a bit harder";
    ]
    command.arguments

let config_when_yaml_contains_codex_settings_parses_typed_configuration () =
  let yaml =
    {|provider: codex
codex_binary: codex-nightly
default_verb: do
model: gpt-5.4-mini
reasoning_effort: high
sandbox: workspace-write
search: true
ephemeral: false
skip_git_repo_check: false
color: never
codex_extra_args:
  - --ignore-rules
|}
  in
  let config = assert_ok (Config.parse_yaml yaml) in
  assert (config.provider = Some Domain.Provider.Codex);
  assert_equal_string "codex-nightly" (Option.get config.codex_binary);
  assert (config.verb = Some Domain.Verb.Do);
  assert_equal_string "gpt-5.4-mini" (Option.get config.model);
  assert (config.reasoning_effort = Some Domain.Reasoning_effort.High);
  assert (config.sandbox = Some Domain.Sandbox.Workspace_write);
  assert (config.search = Some true);
  assert (config.ephemeral = Some false);
  assert (config.skip_git_repo_check = Some false);
  assert (config.color = Some Domain.Color.Never);
  assert_equal_string_list [ "--ignore-rules" ] config.codex_extra_args

let config_when_unknown_field_present_returns_useful_error () =
  match Config.parse_yaml "mystery: true\n" with
  | Ok _ -> fail "expected unknown field to fail"
  | Error message ->
      assert_equal_string "unknown config field \"mystery\"" message

let request_when_config_omits_model_uses_gpt54_and_medium_reasoning () =
  let overrides =
    {
      Request.config_path = None;
      provider = None;
      codex_binary = None;
      verb = None;
      model = None;
      reasoning_effort = None;
      profile = None;
      cwd = None;
      sandbox = None;
      search = None;
      ephemeral = None;
      skip_git_repo_check = None;
      color = None;
      images = [];
      json = false;
      dry_run = false;
      message_words = [ "hello" ];
    }
  in
  let request = Request.resolve Config.empty overrides in
  assert_equal_string "gpt-5.4" request.model;
  assert (request.reasoning_effort = Domain.Reasoning_effort.Medium);
  assert (request.prompt = Some "hello")

let tests =
  [
    ( "CodexCommand-WhenDefaultAskProvided-BuildsCodexExecCommand",
      codex_command_when_default_ask_provided_builds_codex_exec_command );
    ( "CodexCommand-WhenDoVerbWithoutSandbox-BuildsWorkspaceWriteCommand",
      codex_command_when_do_verb_without_sandbox_builds_workspace_write_command
    );
    ( "CodexCommand-WhenReviewVerbProvided-UsesReviewSubcommand",
      codex_command_when_review_verb_provided_uses_review_subcommand );
    ( "CodexCommand-WhenSearchEnabled-UsesCodexConfigOverride",
      codex_command_when_search_enabled_uses_codex_config_override );
    ( "CodexCommand-WhenCustomReasoningEffortProvided-BuildsConfigOverride",
      codex_command_when_custom_reasoning_effort_provided_builds_config_override
    );
    ( "Config-WhenYamlContainsCodexSettings-ParsesTypedConfiguration",
      config_when_yaml_contains_codex_settings_parses_typed_configuration );
    ( "Config-WhenUnknownFieldPresent-ReturnsUsefulError",
      config_when_unknown_field_present_returns_useful_error );
    ( "Request-WhenConfigOmitsModel-UsesGpt54AndMediumReasoning",
      request_when_config_omits_model_uses_gpt54_and_medium_reasoning );
  ]

let run_test (name, test) =
  try
    test ();
    Printf.printf "ok - %s\n%!" name
  with exn ->
    Printf.eprintf "not ok - %s\n%s\n%!" name (Printexc.to_string exn);
    exit 1

let () = List.iter run_test tests
