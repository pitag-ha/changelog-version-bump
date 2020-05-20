open Base

type t = { major : int; minor : int; patch : int }

let to_string vn =
  Int.to_string vn.major ^ "." ^ Int.to_string vn.minor ^ "."
  ^ Int.to_string vn.patch

let from_string s =
  let open Str in
  let regex = regexp "[0-9]+.[0-9]+.[0-9]+" in
  (try search_forward regex s 0 |> Option.some with _ -> None)
  |> Option.map ~f:(fun _ ->
         matched_string s
         |> String.split_on_chars ~on:[ '.' ]
         |> List.map ~f:Caml.int_of_string)
  |> Option.bind ~f:(function
       | [ major; minor; patch ] -> Some { major; minor; patch }
       | _ -> None)

let next version change =
  match change with
  | Change.Breaking -> Ok { major = version.major + 1; minor = 0; patch = 0 }
  | Change.Minor ->
      Ok { major = version.major; minor = version.minor + 1; patch = 0 }
  | Change.Patch -> Ok { version with patch = version.patch + 1 }
  | Change.Unclear -> Error `Internal_error
