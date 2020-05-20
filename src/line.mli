type t =
  | VersionHeader of Version_number.t option
  | ChangeHeader of (Change.tag, string) Caml.result
  | OtherHeader of string
  | Item
  | Empty

type md_header_type = T1 | T2 | T3 | T4 | T5 | T6

type parse_info = {
  version_header_type : md_header_type;
  change_header_type : md_header_type;
}

val read_next_line :
  err_if_none:[ `Empty_changelog | `One_line_changelog ] ->
  in_channel ->
  (string, [ `Empty_changelog | `One_line_changelog ]) result

val get_parse_info :
  string ->
  ( parse_info,
    [> `Empty_changelog
    | `One_line_changelog
    | `No_changes_since of Version_number.t
    | `No_header
    | `Same_header_type
    | `Uncategorized_item
    | `Internal_error ] )
  result

val from_string : string -> parse_info -> t
