open Stdio
open Rresult

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

type line_info =
  | Header of { text : string; header_type : md_header_type }
  | Empty
  | Other

type line_info_vn =
  | Header of { vn_opt : Version_number.t option; header_type : md_header_type }
  | Empty
  | Other

let pre_parse line : line_info =
  let open Omd in
  match of_string line with
  | [] -> Empty
  | [ H1 content ] -> Header { text = to_markdown content; header_type = T1 }
  | [ H2 content ] -> Header { text = to_markdown content; header_type = T2 }
  | [ H3 content ] -> Header { text = to_markdown content; header_type = T3 }
  | [ H4 content ] -> Header { text = to_markdown content; header_type = T4 }
  | [ H5 content ] -> Header { text = to_markdown content; header_type = T5 }
  | [ H6 content ] -> Header { text = to_markdown content; header_type = T6 }
  | _ -> Other

let pre_parse_vn line =
  pre_parse line |> function
  | Header { text; header_type } ->
      Header { vn_opt = Version_number.from_string text; header_type }
  | Empty -> Empty
  | Other -> Other

let read_next_line ~err_if_none:err inc =
  let line = ref (In_channel.input_line inc) in
  while !line = Some "" do
    line := In_channel.input_line inc
  done;
  R.of_option ~none:(fun () -> Error err) !line

let get_parse_info filepath =
  let inc = In_channel.create filepath in
  Base.Exn.protect
    ~f:(fun () ->
      read_next_line ~err_if_none:`Empty_changelog inc >>| pre_parse_vn
      >>= fun first_line ->
      read_next_line ~err_if_none:`One_line_changelog inc >>| pre_parse_vn
      >>= fun second_line ->
      match (first_line, second_line) with
      | ( Header { vn_opt = None; header_type = version_header_type },
          Header { vn_opt = None; header_type = change_header_type } ) ->
          if version_header_type = change_header_type then
            Error `Same_header_type
          else Ok { version_header_type; change_header_type }
      | Header { vn_opt = Some version; _ }, _
      | _, Header { vn_opt = Some version; _ } ->
          Error (`No_changes_since version)
      | Other, _ -> Error `No_header
      | _, Other -> Error `Uncategorized_item
      | Empty, _ | _, Empty -> Error `Internal_error)
    ~finally:(fun () -> In_channel.close inc)

let from_string line { version_header_type; change_header_type } =
  match pre_parse line with
  | Header { text; header_type } when header_type = version_header_type ->
      VersionHeader (Version_number.from_string text)
  | Header { text; header_type } when header_type = change_header_type ->
      ChangeHeader (Change.tag_header text)
  | Header { text; _ } -> OtherHeader text
  | Other -> Item
  | Empty -> Empty
