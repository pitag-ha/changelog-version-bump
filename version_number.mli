type t = { major : int; minor : int; patch : int }

val to_string : t -> string

val from_string : string -> t option

val next : t -> Change.t -> (t, [> `Internal_error ]) result
