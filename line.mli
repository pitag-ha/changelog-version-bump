type t = VersionHeader of string | ChangeHeader of string | Item | Empty

val from_string : string -> t
