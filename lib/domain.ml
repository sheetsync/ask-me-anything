(* Core domain types for the Ask command surface. *)

module Provider = struct
  type t = Codex

  let all = [ ("codex", Codex) ]
  let to_string = function Codex -> "codex"

  let of_string value =
    match String.lowercase_ascii value with
    | "codex" -> Ok Codex
    | _ -> Error (Printf.sprintf "unsupported provider: %s" value)
end

module Verb = struct
  type t = Ask | Do | Review | Raw

  let all = [ ("ask", Ask); ("do", Do); ("review", Review); ("raw", Raw) ]

  let to_string = function
    | Ask -> "ask"
    | Do -> "do"
    | Review -> "review"
    | Raw -> "raw"

  let of_string value =
    match String.lowercase_ascii value with
    | "ask" -> Ok Ask
    | "do" -> Ok Do
    | "review" -> Ok Review
    | "raw" -> Ok Raw
    | _ -> Error (Printf.sprintf "unsupported verb: %s" value)
end

module Sandbox = struct
  type t = Read_only | Workspace_write | Danger_full_access

  let all =
    [
      ("read-only", Read_only);
      ("workspace-write", Workspace_write);
      ("danger-full-access", Danger_full_access);
    ]

  let to_string = function
    | Read_only -> "read-only"
    | Workspace_write -> "workspace-write"
    | Danger_full_access -> "danger-full-access"

  let of_string value =
    match String.lowercase_ascii value with
    | "read-only" -> Ok Read_only
    | "workspace-write" -> Ok Workspace_write
    | "danger-full-access" -> Ok Danger_full_access
    | _ -> Error (Printf.sprintf "unsupported sandbox: %s" value)

  let permits_writes = function
    | Read_only -> false
    | Workspace_write | Danger_full_access -> true
end

module Color = struct
  type t = Always | Never | Auto

  let all = [ ("always", Always); ("never", Never); ("auto", Auto) ]

  let to_string = function
    | Always -> "always"
    | Never -> "never"
    | Auto -> "auto"

  let of_string value =
    match String.lowercase_ascii value with
    | "always" -> Ok Always
    | "never" -> Ok Never
    | "auto" -> Ok Auto
    | _ -> Error (Printf.sprintf "unsupported color: %s" value)
end

module Reasoning_effort = struct
  type t = Minimal | Low | Medium | High | Xhigh

  let all =
    [
      ("minimal", Minimal);
      ("low", Low);
      ("medium", Medium);
      ("high", High);
      ("xhigh", Xhigh);
    ]

  let to_string = function
    | Minimal -> "minimal"
    | Low -> "low"
    | Medium -> "medium"
    | High -> "high"
    | Xhigh -> "xhigh"

  let of_string value =
    match String.lowercase_ascii value with
    | "minimal" -> Ok Minimal
    | "low" -> Ok Low
    | "medium" -> Ok Medium
    | "high" -> Ok High
    | "xhigh" | "extra-high" | "extra_high" -> Ok Xhigh
    | _ -> Error (Printf.sprintf "unsupported reasoning effort: %s" value)
end
