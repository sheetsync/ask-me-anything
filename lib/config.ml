(* YAML configuration loading and validation for Ask. *)

open Result_syntax

type t = {
  provider : Domain.Provider.t option;
  codex_binary : string option;
  verb : Domain.Verb.t option;
  model : string option;
  reasoning_effort : Domain.Reasoning_effort.t option;
  profile : string option;
  cwd : string option;
  sandbox : Domain.Sandbox.t option;
  search : bool option;
  ephemeral : bool option;
  skip_git_repo_check : bool option;
  color : Domain.Color.t option;
  codex_extra_args : string list;
}

let default_model = "gpt-5.4"
let default_reasoning_effort = Domain.Reasoning_effort.Medium

let empty =
  {
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
    codex_extra_args = [];
  }

let allowed_keys =
  [
    "provider";
    "codex_binary";
    "default_verb";
    "model";
    "reasoning_effort";
    "profile";
    "cwd";
    "sandbox";
    "search";
    "ephemeral";
    "skip_git_repo_check";
    "color";
    "codex_extra_args";
  ]

let option_of_member name members =
  match List.assoc_opt name members with
  | Some `Null | None -> Ok None
  | Some value -> Ok (Some value)

let require_string field = function
  | `String value -> Ok value
  | _ -> Error (Printf.sprintf "config field %S must be a string" field)

let require_bool field = function
  | `Bool value -> Ok value
  | _ -> Error (Printf.sprintf "config field %S must be a boolean" field)

let require_string_list field = function
  | `A values ->
      let rec loop parsed = function
        | [] -> Ok (List.rev parsed)
        | `String value :: remaining -> loop (value :: parsed) remaining
        | _ :: _ ->
            Error
              (Printf.sprintf "config field %S must be an array of strings"
                 field)
      in
      loop [] values
  | _ -> Error (Printf.sprintf "config field %S must be an array" field)

let parse_optional field parser members =
  let* value = option_of_member field members in
  match value with
  | None -> Ok None
  | Some value -> parser value |> Result.map Option.some

let parse_provider value =
  let* text = require_string "provider" value in
  Domain.Provider.of_string text

let parse_verb value =
  let* text = require_string "default_verb" value in
  Domain.Verb.of_string text

let parse_reasoning_effort value =
  let* text = require_string "reasoning_effort" value in
  Domain.Reasoning_effort.of_string text

let parse_sandbox value =
  let* text = require_string "sandbox" value in
  Domain.Sandbox.of_string text

let parse_color value =
  let* text = require_string "color" value in
  Domain.Color.of_string text

let validate_known_keys members =
  let unknown_keys =
    members |> List.map fst
    |> List.filter (fun key -> not (List.mem key allowed_keys))
  in
  match unknown_keys with
  | [] -> Ok ()
  | [ key ] -> Error (Printf.sprintf "unknown config field %S" key)
  | keys ->
      Error
        (Printf.sprintf "unknown config fields: %s"
           (String.concat ", " (List.map (Printf.sprintf "%S") keys)))

let parse_yaml_value = function
  | `O members ->
      let* () = validate_known_keys members in
      let* provider = parse_optional "provider" parse_provider members in
      let* codex_binary =
        parse_optional "codex_binary" (require_string "codex_binary") members
      in
      let* verb = parse_optional "default_verb" parse_verb members in
      let* model = parse_optional "model" (require_string "model") members in
      let* reasoning_effort =
        parse_optional "reasoning_effort" parse_reasoning_effort members
      in
      let* profile =
        parse_optional "profile" (require_string "profile") members
      in
      let* cwd = parse_optional "cwd" (require_string "cwd") members in
      let* sandbox = parse_optional "sandbox" parse_sandbox members in
      let* search = parse_optional "search" (require_bool "search") members in
      let* ephemeral =
        parse_optional "ephemeral" (require_bool "ephemeral") members
      in
      let* skip_git_repo_check =
        parse_optional "skip_git_repo_check"
          (require_bool "skip_git_repo_check")
          members
      in
      let* color = parse_optional "color" parse_color members in
      let* codex_extra_args =
        match List.assoc_opt "codex_extra_args" members with
        | None | Some `Null -> Ok []
        | Some value -> require_string_list "codex_extra_args" value
      in
      Ok
        {
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
          codex_extra_args;
        }
  | _ -> Error "config file must contain a YAML mapping"

let parse_yaml text =
  match Yaml.of_string text with
  | Ok value -> parse_yaml_value value
  | Error (`Msg message) ->
      Error (Printf.sprintf "could not parse YAML: %s" message)

let read_all path =
  let channel = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in_noerr channel)
    (fun () -> really_input_string channel (in_channel_length channel))

let read_file path =
  try read_all path |> parse_yaml
  with Sys_error message ->
    Error (Printf.sprintf "could not read config %S: %s" path message)

let rec read_first_existing = function
  | [] -> Ok empty
  | path :: remaining ->
      if Sys.file_exists path then read_file path
      else read_first_existing remaining
