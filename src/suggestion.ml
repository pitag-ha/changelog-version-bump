open Base
open Stdio
open Rresult

type t = {
  suggestion : Version_number.t;
  semantic_change : Change.t;
  unknown_headers : string list;
}

let make filename =
  let inc = In_channel.create filename in
  Exn.protect
    ~f:(fun () ->
      (* parse first line *)
      R.of_option
        ~none:(fun () -> Error `Empty_changelog)
        (In_channel.input_line inc)
      >>| Line.from_string
      >>= function
      | Empty | Item | ChangeHeader _ -> Error `Lacks_unreleased
      | VersionHeader (Some last) -> Error (`No_changes_since last)
      | VersionHeader None -> (
          (* parse rest of lines *)
          let semantic_change, _, _, last_release, item_in_changed, warning =
            In_channel.fold_lines inc
              ~init:(Change.Unclear, None, false, None, false, [])
              ~f:(fun ( ( min_change,
                          paragraph_tagging,
                          done_parsing,
                          last_release,
                          item_in_changed,
                          warning ) as state )
                      line
                      ->
                if done_parsing then state
                else
                  match Line.from_string line with
                  | Empty -> state
                  | Item -> (
                      match paragraph_tagging with
                      | None -> state
                      | Some (Change.Tagged_as change) ->
                          if Change.is_greater_equal change min_change then
                            ( change,
                              paragraph_tagging,
                              done_parsing,
                              last_release,
                              item_in_changed,
                              warning )
                          else state
                      | Some Changed ->
                          ( min_change,
                            paragraph_tagging,
                            done_parsing,
                            last_release,
                            true,
                            warning ) )
                  | ChangeHeader (Ok known_header) ->
                      ( min_change,
                        Some known_header,
                        done_parsing,
                        last_release,
                        item_in_changed,
                        warning )
                  | ChangeHeader (Error strange_header) ->
                      ( min_change,
                        None,
                        done_parsing,
                        last_release,
                        item_in_changed,
                        strange_header :: warning )
                  | VersionHeader release ->
                      ( min_change,
                        paragraph_tagging,
                        true,
                        release,
                        item_in_changed,
                        warning ))
          in
          if
            item_in_changed
            && not (Change.equal semantic_change Change.Breaking)
          then Error `Item_in_changed
          else
            match (last_release, semantic_change) with
            | None, Unclear -> Error `Both_unclear
            | None, _ -> Error (`Last_release_unclear semantic_change)
            | _, Unclear -> Error `Change_unclear
            | Some last_release, _ ->
                Version_number.next last_release semantic_change
                >>| fun suggestion ->
                {
                  suggestion;
                  semantic_change;
                  unknown_headers = List.rev warning;
                } ))
    ~finally:(fun () -> In_channel.close inc)
