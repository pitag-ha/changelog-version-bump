open Base

type t =
  | VersionHeader of Version_number.t option
  | ChangeHeader of (Change.tag, string) Caml.result
  | Item
  | Empty

let from_string line =
  let f = function "" -> false | _ -> true in
  match String.split line ~on:' ' |> List.filter ~f with
  | [] -> Empty
  (* todo: use OMD instead of doing this manually *)
  | "##" :: v :: _ -> VersionHeader (Version_number.from_string v)
  | "###" :: ch :: _ -> ChangeHeader (Change.tag_header ch)
  | _ -> Item
