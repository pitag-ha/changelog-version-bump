open Printf

let () =
  match Suggestion.make "test_change_log.md" with
  | Ok { suggestion; semantic_change; unknown_headers } ->
      Change.to_string semantic_change
      |> eprintf "Info: The change has been tagged as a %s.\n"
      |> fun () ->
      List.iter
        (fun header ->
          Change.header_table
          |> List.map (fun (known_header, _) -> known_header)
          |> String.concat ", "
          |> eprintf
               "Warning: Header \"%s\" has been ignored since it doesn't match \
                any of the changelog standard headers: %s.\n"
               header)
        unknown_headers
      |> fun () -> printf "%s\n" (Version_number.to_string suggestion)
  | Error `Empty_changelog -> eprintf "Error: Your change log is empty.\n"
  | Error `Lacks_unreleased ->
      eprintf
        "Error: Wrong changelog format: The changelog should start with `### \
         unreleased`, not with an item or a `##`-header such as `## Added`. \n"
  | Error (`No_changes_since last_change) ->
      Version_number.to_string last_change
      |> eprintf "Error: No changes since release %s. \n"
  | Error `Both_unclear ->
      eprintf "Error: This seems to be the first release." |> fun () ->
      eprintf
        "Error: We can't suggest a new version number, sorry. Is the \
         changelog  up-to-date?"
  | Error `Change_unclear ->
      eprintf
        "Error: We can't suggest a new version number, sorry. Is the \
         changelog  up-to-date?"
  | Error (`Last_release_unclear semantic_change) ->
      eprintf "Error: This seems to be the first release." |> fun () ->
      eprintf "Info: The change has been tagged as a %s.\n"
        (Change.to_string semantic_change)
  | Error `Item_in_changed ->
      eprintf
        "Changes listed under the `Changed` header leave too much room for  \
         interpretation to tag them well. Sorry."
  | Error `Internal_error ->
      eprintf "Error: There's been an internal error. Please, file an issue."
