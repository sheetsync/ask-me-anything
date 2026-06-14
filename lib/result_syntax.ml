(* Small result helpers used to keep validation and parsing code explicit. *)

let ( let* ) value next = Result.bind value next
let ( let+ ) value next = Result.map next value
