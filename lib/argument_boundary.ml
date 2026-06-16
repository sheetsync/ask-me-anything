(* Splits Ask options from the English prompt before Cmdliner parses options. *)

type t = { option_argv : string array; message_words : string list }
type option_kind = Flag | Value

let flag_options =
  [
    "--dry-run";
    "--ephemeral";
    "--help";
    "--json";
    "--no-search";
    "--require-git-repo";
    "--save-session";
    "--search";
    "--skip-git-check";
    "--version";
  ]

let value_options =
  [
    "--as";
    "--codex-binary";
    "--color";
    "--config";
    "--cwd";
    "--effort";
    "--image";
    "--model";
    "--profile";
    "--provider";
    "--reasoning-effort";
    "--sandbox";
    "--verb";
    "-C";
    "-i";
    "-m";
    "-p";
    "-s";
  ]

let long_option_name token =
  match String.split_on_char '=' token with name :: _ -> name | [] -> token

let classify token =
  let name =
    if String.starts_with ~prefix:"--" token then long_option_name token
    else token
  in
  if List.mem name flag_options then Some Flag
  else if List.mem name value_options then Some Value
  else None

let append_option option_arguments token = token :: option_arguments

let build_option_argv program option_arguments =
  Array.of_list (program :: List.rev option_arguments)

let split argv =
  let arguments = Array.to_list argv in
  match arguments with
  | [] -> { option_argv = [||]; message_words = [] }
  | program :: tokens ->
      let rec loop option_arguments = function
        | [] ->
            {
              option_argv = build_option_argv program option_arguments;
              message_words = [];
            }
        | "--" :: prompt_words ->
            {
              option_argv = build_option_argv program option_arguments;
              message_words = prompt_words;
            }
        | token :: remaining -> (
            match classify token with
            | Some Flag -> loop (append_option option_arguments token) remaining
            | Some Value when String.contains token '=' ->
                loop (append_option option_arguments token) remaining
            | Some Value -> (
                match remaining with
                | [] ->
                    {
                      option_argv =
                        build_option_argv program
                          (append_option option_arguments token);
                      message_words = [];
                    }
                | value :: rest ->
                    loop (value :: append_option option_arguments token) rest)
            | None ->
                {
                  option_argv = build_option_argv program option_arguments;
                  message_words = token :: remaining;
                })
      in
      loop [] tokens
