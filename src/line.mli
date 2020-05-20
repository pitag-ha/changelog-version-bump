type t =
  | VersionHeader of Version_number.t option
  | ChangeHeader of (Change.tag, string) Caml.result
  | Item
  | Empty

val from_string : string -> t
