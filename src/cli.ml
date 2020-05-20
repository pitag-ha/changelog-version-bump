open Cmdliner
open Stdio
open Printf
open Option

type parse_result = { version_number : string option; exit : int }

let parse_changelog changelog_path =
  match Suggestion.make changelog_path with
  | Ok { suggestion; semantic_change; unknown_headers } ->
      Change.to_string semantic_change
      |> eprintf "Info: The change has been tagged as a %s.\n";
      List.iter
        (fun header ->
          Change.header_table
          |> List.map (fun (known_header, _) -> known_header)
          |> String.concat ", "
          |> eprintf
               "Warning: Header \"%s\" has been ignored since it doesn't match \
                any of the changelog standard headers: %s.\n"
               header)
        unknown_headers;
      { version_number = some (Version_number.to_string suggestion); exit = 0 }
  | Error `Empty_changelog ->
      eprintf "Error: Your change log is empty.\n";
      { version_number = none; exit = 2 }
  | Error `Lacks_unreleased ->
      eprintf
        "Error: Wrong changelog format: The changelog should start with `### \
         unreleased`, not with an item or a `##`-header such as `## Added`. \n";
      { version_number = none; exit = 3 }
  | Error (`No_changes_since last_change) ->
      Version_number.to_string last_change
      |> eprintf "Error: No changes since release %s. \n";
      { version_number = none; exit = 4 }
  | Error `Both_unclear ->
      eprintf "Error: This seems to be the first release." |> fun () ->
      eprintf
        "Error: We can't suggest a new version number, sorry. Is the changelog \
         up-to-date?";
      { version_number = none; exit = 5 }
  | Error `Change_unclear ->
      eprintf
        "Error: We can't suggest a new version number, sorry. Is the changelog \
         up-to-date?";
      { version_number = none; exit = 6 }
  | Error (`Last_release_unclear semantic_change) ->
      eprintf "Error: This seems to be the first release." |> fun () ->
      eprintf "Info: The change has been tagged as a %s.\n"
        (Change.to_string semantic_change);
      { version_number = none; exit = 7 }
  | Error `Item_in_changed ->
      eprintf
        "Changes listed under the `Changed` header leave too much room for \
         interpretation to tag them well. Sorry.";
      { version_number = none; exit = 8 }
  | Error `Internal_error ->
      eprintf "Error: There's been an internal error. Please, file an issue.";
      { version_number = none; exit = 9 }

let new_version_number changelog_path =
  match parse_changelog changelog_path with
  | { version_number = Some vn; exit = 0 } -> printf "%s\n" vn |> fun () -> 0
  | { exit; _ } -> exit

let new_changelog changelog_path =
  match parse_changelog changelog_path with
  | { version_number = Some vn; exit = 0 } ->
      printf "## unreleased\n\n";
      Change.header_table
      |> List.iter (fun (header, _) -> printf "### %s\n\n" header);
      let date = Unix.time () |> Unix.localtime in
      printf "## %s (%i-%i-%i)\n" vn (date.tm_year + 1900) (date.tm_mon + 1)
        date.tm_mday;
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
