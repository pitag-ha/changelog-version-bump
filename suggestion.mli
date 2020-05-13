type t = {
  suggestion : Version_number.t;
  semantic_change : Change.t;
  unknown_headers : string list;
}

val make :
  string ->
  ( t,
    [> `Internal_error
    | `Empty_changelog
    | `Lacks_unreleased
    | `No_changes_since of Version_number.t
    | `Change_unclear
    | `Last_release_unclear of Change.t
    | `Both_unclear
    | `Item_in_changed ] )
  result
