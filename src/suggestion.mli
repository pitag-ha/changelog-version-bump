type t = {
  suggestion : Version_number.t;
  semantic_change : Change.t;
  unknown_headers : string list;
}

val make :
  string ->
  Line.parse_info ->
  ( t,
    [> `Internal_error
    | `Change_unclear
    | `Last_release_unclear of Change.t
    | `Both_unclear
    | `Item_in_changed ] )
  result
