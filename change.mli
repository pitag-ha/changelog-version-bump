type t = Breaking | Minor | Patch | Unclear

val is_greater_equal : t -> t -> bool

val tag_header : string -> t option

val to_string : t -> string
