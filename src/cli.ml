open Cmdliner
open Stdio
open Printf
open Option

type parse_result = {
  version_number : string option;
  exit : int;
  headers : Line.parse_info option;
}

let parse_changelog changelog_path =
  match Line.get_parse_info changelog_path with
  | Ok parse_info -> (
      match Suggestion.make changelog_path parse_info with
      | Ok { suggestion; semantic_change; unknown_headers } ->
          Change.to_string semantic_change
          |> eprintf "Info: The change has been tagged as a %s.\n";
          List.iter
            (fun header ->
              Change.header_table
              |> List.map (fun (known_header, _) -> known_header)
              |> String.concat ", "
              |> eprintf
                   "Warning: Header \"%s\" has been ignored: either its header \
                    type doesn't match the previous ones or \n\
                   \  its content doesn't match any of the changelog standard \
                    headers: %s.\n"
                   header)
            unknown_headers;
          {
            version_number = some (Version_number.to_string suggestion);
            exit = 0;
            headers = Some parse_info;
          }
      | Error `Both_unclear ->
          eprintf "Error: This seems to be the first release.\n" |> fun () ->
          eprintf
            "Error: We can't suggest a new version number. Is the changelog \
             up-to-date?\n";
          { version_number = none; exit = 5; headers = Some parse_info }
      | Error `Change_unclear ->
          eprintf
            "Error: We can't suggest a new version number. Is the changelog \
             up-to-date?\n";
          { version_number = none; exit = 6; headers = Some parse_info }
      | Error (`Last_release_unclear semantic_change) ->
          eprintf "Error: This seems to be the first release.\n" |> fun () ->
          eprintf "Info: The change has been tagged as a %s.\n"
            (Change.to_string semantic_change);
          { version_number = none; exit = 7; headers = Some parse_info }
      | Error (`Item_in_changed semantic_change) ->
          eprintf
            "Error: Changes listed under the `Changed` header leave too much \
             room for interpretation to automatically deduce the semantic \
             change.";
          let _ =
            match semantic_change with
            | Unclear -> eprintf "\n"
            | Patch | Minor ->
                eprintf
                  " If it wasn't for those items, we'd suggest to tag the new \
                   version as a %s.\n"
                  (Change.to_string semantic_change)
            | Breaking ->
                eprintf "Furthermore, there's been an internal error.\n"
          in
          { version_number = none; exit = 8; headers = Some parse_info }
      | Error `Internal_error ->
          eprintf
            "Error: There's been an internal error. Please, file an issue.\n";
          { version_number = none; exit = 9; headers = Some parse_info } )
  | Error `Empty_changelog ->
      eprintf "Your changelog is empty.\n";
      { version_number = none; exit = 1; headers = None }
  | Error `One_line_changelog ->
      eprintf
        "The changelog seems to only contain one line. Is it up-to-date?\n";
      { version_number = none; exit = 2; headers = None }
  | Error `No_header ->
      eprintf
        "Error: Wrong format: the changelog should start with a header \
         containing \"unreleased\" or similar.\n";
      { version_number = none; exit = 3; headers = None }
  | Error (`No_changes_since last_change) ->
      Version_number.to_string last_change
      |> eprintf "Error: No changes since release: %s. \n";
      { version_number = none; exit = 4; headers = None }
  | Error `Uncategorized_item ->
      eprintf
        "Error: After the \"unreleased\"-header there has to be a header \
         containing a category like \"Added\".\n";
      { version_number = none; exit = 10; headers = None }
  | Error `Same_header_type ->
      eprintf
        "Parse error: The change header type seems to coincide with the \
         version header type.\n";
      { version_number = none; exit = 11; headers = None }
  | Error `Internal_error ->
      eprintf "Error: There's been an internal error. Please, file an issue.\n";
      { version_number = none; exit = 9; headers = None }

let new_version_number changelog_path =
  match parse_changelog changelog_path with
  | { version_number = Some vn; exit = 0; _ } -> printf "%s\n" vn |> fun () -> 0
  | { exit; _ } -> exit

let print_skeleton hi vn =
  let open Line in
  let header_to_string : md_header_type -> ('a, out_channel, unit, unit) format4
      = function
    | T1 -> "# "
    | T2 -> "## "
    | T3 -> "### "
    | T4 -> "#### "
    | T5 -> "##### "
    | T6 -> "###### "
  in
  header_to_string hi.version_header_type |> printf;
  printf "unreleased\n\n";
  Change.header_table
  |> List.iter (fun (header, _) ->
         header_to_string hi.change_header_type |> printf;
         printf "%s\n\n" header);
  header_to_string hi.version_header_type |> printf;
  let date = Unix.time () |> Unix.localtime in
  printf "%s (%i-%i-%i)\n" vn (date.tm_year + 1900) (date.tm_mon + 1)
    date.tm_mday;
  ()

let new_changelog changelog_path =
  match parse_changelog changelog_path with
  | { version_number = Some vn; exit = 0; headers = Some header_info } ->
      print_skeleton header_info vn;
      let inc = In_channel.create changelog_path in
      In_channel.input_line inc |> fun _ ->
      In_channel.iter_lines inc ~f:(fun line -> printf "%s\n" line) |> fun () ->
      0
  | { exit; _ } -> exit

let path =
  let doc = "The path to the changelog." in
  Arg.(required & pos 0 (some string) None & info [] ~doc ~docv:"PATH")

let version_number_cmd =
  ( Term.(const new_version_number $ path),
    Term.info "print-version-number"
      ~doc:"Print a suggestion for the next semantic version number." )

let gen_changelog_cmd =
  ( Term.(const new_changelog $ path),
    Term.info "changelog-bump" ~doc:"Print the updated changelog." )

let () =
  Term.exit_status
  @@ Term.eval_choice gen_changelog_cmd
       [ gen_changelog_cmd; version_number_cmd ]
