(* Process execution that preserves Codex streaming output and exit status. *)

let exit_code_of_status = function
  | Unix.WEXITED code -> code
  | Unix.WSIGNALED signal -> 128 + signal
  | Unix.WSTOPPED signal -> 128 + signal

let run command =
  let argv =
    Array.of_list (command.Codex_command.executable :: command.arguments)
  in
  try
    let pid =
      Unix.create_process command.executable argv Unix.stdin Unix.stdout
        Unix.stderr
    in
    let _, status = Unix.waitpid [] pid in
    exit_code_of_status status
  with Unix.Unix_error (error, operation, value) ->
    Printf.eprintf "ask: could not run %s (%s %s: %s)\n%!" command.executable
      operation value (Unix.error_message error);
    127
