open Base

type t = VersionHeader of string | ChangeHeader of string | Item | Empty

let from_string line =
  let f = function "" -> false | _ -> true in
  match String.split line ~on:' ' |> List.filter ~f with
  | [] -> Empty
  (* todo: use OMD instead of doing this manually *)
  | "##" :: v :: _ -> VersionHeader v
  | "###" :: ch :: _ -> ChangeHeader ch
  | _ -> Item
