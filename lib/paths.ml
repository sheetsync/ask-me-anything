(* Configuration path discovery for local and XDG-style installations. *)

let getenv_non_empty name =
  match Sys.getenv_opt name with
  | Some "" | None -> None
  | Some value -> Some value

let join left right = Filename.concat left right

let default_config_paths () =
  match getenv_non_empty "ASK_CONFIG" with
  | Some path -> [ path ]
  | None -> (
      match getenv_non_empty "XDG_CONFIG_HOME" with
      | Some config_home ->
          let ask_config_home = join config_home "ask" in
          [
            join ask_config_home "config.yaml";
            join ask_config_home "config.yml";
          ]
      | None -> (
          match getenv_non_empty "HOME" with
          | Some home ->
              let ask_config_home = join (join home ".config") "ask" in
              [
                join ask_config_home "config.yaml";
                join ask_config_home "config.yml";
              ]
          | None -> []))
