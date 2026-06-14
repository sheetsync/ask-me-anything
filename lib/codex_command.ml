(* Translation from Ask's domain model into a concrete codex argv vector. *)

open Result_syntax

type t = { executable : string; arguments : string list }

let effective_sandbox request =
  match (request.Request.verb, request.sandbox) with
  | Domain.Verb.Do, None -> Some Domain.Sandbox.Workspace_write
  | _, sandbox -> sandbox

let should_skip_git_repo_check request sandbox =
  match request.Request.skip_git_repo_check with
  | Some value -> value
  | None -> (
      match sandbox with
      | Some sandbox -> not (Domain.Sandbox.permits_writes sandbox)
      | None -> true)

let prompt_argument request = Option.value request.Request.prompt ~default:"-"

let add_optional flag render value arguments =
  match value with
  | None -> arguments
  | Some value -> arguments @ [ flag; render value ]

let add_switch flag enabled arguments =
  if enabled then arguments @ [ flag ] else arguments

let add_config_override key value arguments =
  arguments @ [ "-c"; Printf.sprintf "%s=%S" key value ]

let validate_review_request request =
  let unsupported =
    [
      ("--profile", Option.is_some request.Request.profile);
      ("--cwd", Option.is_some request.cwd);
      ("--sandbox", Option.is_some request.sandbox);
      ("--color", Option.is_some request.color);
      ("--image", request.images <> []);
      ("--search", request.search);
    ]
    |> List.filter snd |> List.map fst
  in
  match unsupported with
  | [] -> Ok ()
  | flags ->
      Error
        (Printf.sprintf
           "codex exec review does not support these ask options yet: %s"
           (String.concat ", " flags))

let build_exec_arguments request =
  let sandbox = effective_sandbox request in
  ( ( [ "exec" ]
    |> (fun arguments -> arguments @ [ "-m"; request.Request.model ])
    |> add_optional "-p" Fun.id request.profile
    |> add_optional "-C" Fun.id request.cwd
    |> add_optional "-s" Domain.Sandbox.to_string sandbox
    |> add_optional "--color" Domain.Color.to_string request.color
    |> add_switch "--ephemeral" request.ephemeral
    |> add_switch "--skip-git-repo-check"
         (should_skip_git_repo_check request sandbox)
    |> (fun arguments ->
    List.fold_left
      (fun acc image -> acc @ [ "--image"; image ])
      arguments request.images)
    |> add_switch "--json" request.json
    |> add_config_override "model_reasoning_effort"
         (Domain.Reasoning_effort.to_string request.reasoning_effort)
    |> fun arguments ->
      if request.search then arguments @ [ "-c"; "web_search=\"live\"" ]
      else arguments )
  |> fun arguments -> arguments @ request.codex_extra_args )
  |> fun arguments -> arguments @ [ prompt_argument request ]

let build_review_arguments request =
  let* () = validate_review_request request in
  let sandbox = effective_sandbox request in
  let arguments =
    ( [ "exec"; "review"; "--uncommitted" ]
    |> (fun arguments -> arguments @ [ "-m"; request.Request.model ])
    |> add_switch "--ephemeral" request.ephemeral
    |> add_switch "--skip-git-repo-check"
         (should_skip_git_repo_check request sandbox)
    |> add_switch "--json" request.json
    |> add_config_override "model_reasoning_effort"
         (Domain.Reasoning_effort.to_string request.reasoning_effort)
    |> fun arguments -> arguments @ request.codex_extra_args )
    |> fun arguments -> arguments @ [ prompt_argument request ]
  in
  Ok arguments

let build request =
  match request.Request.provider with
  | Domain.Provider.Codex ->
      let+ arguments =
        match request.verb with
        | Domain.Verb.Review -> build_review_arguments request
        | Domain.Verb.Ask | Domain.Verb.Do | Domain.Verb.Raw ->
            Ok (build_exec_arguments request)
      in
      { executable = request.codex_binary; arguments }

let quote_for_shell value =
  let is_safe_character = function
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '-' | '.' | '/' | ':' | '='
      ->
        true
    | _ -> false
  in
  if value <> "" && String.for_all is_safe_character value then value
  else "'" ^ String.concat "'\\''" (String.split_on_char '\'' value) ^ "'"

let to_shell command =
  command.executable :: command.arguments
  |> List.map quote_for_shell |> String.concat " "
