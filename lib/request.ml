(* Resolution of config-file settings and command-line overrides. *)

type cli_overrides = {
  config_path : string option;
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
  images : string list;
  json : bool;
  dry_run : bool;
  message_words : string list;
}

type t = {
  provider : Domain.Provider.t;
  codex_binary : string;
  verb : Domain.Verb.t;
  model : string;
  reasoning_effort : Domain.Reasoning_effort.t;
  profile : string option;
  cwd : string option;
  sandbox : Domain.Sandbox.t option;
  search : bool;
  ephemeral : bool;
  skip_git_repo_check : bool option;
  color : Domain.Color.t option;
  images : string list;
  json : bool;
  dry_run : bool;
  prompt : string option;
  codex_extra_args : string list;
}

let first_some preferred fallback =
  match preferred with Some _ -> preferred | None -> fallback

let prompt_from_words = function
  | [] -> None
  | words -> Some (String.concat " " words)

let resolve (config : Config.t) (overrides : cli_overrides) =
  {
    provider =
      Option.value
        (first_some overrides.provider config.Config.provider)
        ~default:Domain.Provider.Codex;
    codex_binary =
      Option.value
        (first_some overrides.codex_binary config.codex_binary)
        ~default:"codex";
    verb =
      Option.value
        (first_some overrides.verb config.verb)
        ~default:Domain.Verb.Ask;
    model =
      Option.value
        (first_some overrides.model config.model)
        ~default:Config.default_model;
    reasoning_effort =
      Option.value
        (first_some overrides.reasoning_effort config.reasoning_effort)
        ~default:Config.default_reasoning_effort;
    profile = first_some overrides.profile config.profile;
    cwd = first_some overrides.cwd config.cwd;
    sandbox = first_some overrides.sandbox config.sandbox;
    search =
      Option.value (first_some overrides.search config.search) ~default:false;
    ephemeral =
      Option.value
        (first_some overrides.ephemeral config.ephemeral)
        ~default:true;
    skip_git_repo_check =
      first_some overrides.skip_git_repo_check config.skip_git_repo_check;
    color = first_some overrides.color config.color;
    images = overrides.images;
    json = overrides.json;
    dry_run = overrides.dry_run;
    prompt = prompt_from_words overrides.message_words;
    codex_extra_args = config.codex_extra_args;
  }
