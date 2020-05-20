type t = Breaking | Minor | Patch | Unclear

type tag = Tagged_as of t | Changed

val header_table : (string * tag) list

val equal : t -> t -> bool

val is_greater_equal : t -> t -> bool

val tag_header : string -> (tag, string) Caml.result

val to_string : t -> string
