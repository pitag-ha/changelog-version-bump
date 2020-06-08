open Base
open Stdio
open Rresult

type t = {
  suggestion : Version_number.t;
  semantic_change : Change.t;
  unknown_headers : string list;
}

(* let get_parse_info filepath *)

let make filepath parse_info =
  let inc = In_channel.create filepath in
  Exn.protect
    ~f:(fun () ->
      let _ = Line.read_next_line ~err_if_none:`Empty_changelog inc in
      let semantic_change, _, _, last_release, item_in_changed, warning =
        In_channel.fold_lines inc
          ~init:(Change.Unclear, None, false, None, false, [])
          ~f:(fun ( ( min_change,
                      paragraph_kind,
                      done_parsing,
                      last_release,
                      item_in_changed,
                      warning ) as state )
                  line
                  ->
            if done_parsing then state
            else
              match Line.from_string line parse_info with
              | Empty -> state
              | Item -> (
                  let open Change in
                  match paragraph_kind with
                  | None -> state
                  | Some (Tagged_as sem_change) ->
                      if is_greater_equal sem_change min_change then
                        ( sem_change,
                          paragraph_kind,
                          done_parsing,
                          last_release,
                          item_in_changed,
                          warning )
                      else state
                  | Some Changed_header ->
                      ( min_change,
                        paragraph_kind,
                        done_parsing,
                        last_release,
                        true,
                        warning ) )
              | ChangeHeader (Ok known_change_header) ->
                  ( min_change,
                    Some known_change_header,
                    done_parsing,
                    last_release,
                    item_in_changed,
                    warning )
              | ChangeHeader (Error strange_header) | OtherHeader strange_header
                ->
                  ( min_change,
                    None,
                    done_parsing,
                    last_release,
                    item_in_changed,
                    strange_header :: warning )
              | VersionHeader release ->
                  ( min_change,
                    paragraph_kind,
                    true,
                    release,
                    item_in_changed,
                    warning ))
      in
      if item_in_changed && not (Change.equal semantic_change Change.Breaking)
      then Error (`Item_in_changed semantic_change)
      else
        match (last_release, semantic_change) with
        | None, Unclear -> Error `Both_unclear
        | None, _ -> Error (`Last_release_unclear semantic_change)
        | _, Unclear -> Error `Change_unclear
        | Some last_release, sem_change ->
            Version_number.next last_release sem_change >>| fun suggestion ->
            { suggestion; semantic_change; unknown_headers = List.rev warning })
    ~finally:(fun () -> In_channel.close inc)
