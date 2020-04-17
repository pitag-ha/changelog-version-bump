open Base
open Stdio

let parse_logs filename =
  let inc = In_channel.create filename in
  Exn.protect
    ~f:(fun () ->
      (* parse first line *)
      match In_channel.input_line inc with
      | None -> "Your change log is empty. \n"
      | Some line -> (
          match Line.from_string line with
          | Empty | Item | ChangeHeader _ ->
              failwith
                "Your change log should start with `### unreleased`, not with \
                 an item or a `##`-header such as `## Added`. \n"
          | VersionHeader version -> (
              match Version_number.from_string version with
              | Some v ->
                  Version_number.to_string v
                  |> Printf.sprintf
                       "There haven't been any changes recorded since release \
                        %s. \n"
                  |> failwith
              | None -> (
                  (* parse rest of lines *)
                  let semantic_change, _, _, last_release =
                    In_channel.fold_lines inc
                      ~init:(Change.Unclear, Change.Unclear, false, None)
                      ~f:(fun ((min_change, paragraph, done_parsing, _) as state)
                              line
                              ->
                        if done_parsing then state
                        else
                          match Line.from_string line with
                          | Empty -> state
                          | Item ->
                              if Change.is_greater_equal paragraph min_change
                              then (paragraph, paragraph, false, None)
                              else state
                          | ChangeHeader new_paragraph -> (
                              match Change.tag_header new_paragraph with
                              | Some p -> (min_change, p, false, None)
                              | None ->
                                  Printf.sprintf
                                    "Parsing error at header %s. \n"
                                    new_paragraph
                                  |> failwith )
                          | VersionHeader release ->
                              ( min_change,
                                paragraph,
                                true,
                                Version_number.from_string release ))
                  in
                  match last_release with
                  | None -> (
                      match semantic_change with
                      | Unclear ->
                          failwith
                            "The last release version number is not reported \
                             in the change log. We also can't suggest a \
                             semantic change tagging. \n"
                      | _ ->
                          Change.to_string semantic_change
                          |> Printf.sprintf
                               "The last release version number is not \
                                reported in the change log. We suggest to tag \
                                the change as a %s though. \n"
                          |> failwith )
                  | Some release -> (
                      match Version_number.next release semantic_change with
                      | None ->
                          failwith
                            "We can't suggest a new version number, sorry. \
                             Maybe, all changes are under the \
                             `Changed`-header?"
                      | Some version -> Version_number.to_string version ) ) ) ))
    ~finally:(fun () -> In_channel.close inc)

(* todo: decide how to expose the tool to the user *)
let () = printf "%s \n" (parse_logs "test_change_log.md")
