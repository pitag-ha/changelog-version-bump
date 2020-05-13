open Base

type t = { major : int; minor : int; patch : int }

let to_string vn =
  Int.to_string vn.major ^ "." ^ Int.to_string vn.minor ^ "."
  ^ Int.to_string vn.patch

let from_string s =
  (* todo: use regex insted of split on '.' so that different formats like `[0.0.1]`, `0.0.1`, `release 0.0.1` etc. are accepted *)
  match
    String.split_on_chars ~on:[ '.' ] s |> List.map ~f:Caml.int_of_string_opt
  with
  | [ Some major; Some minor; Some patch ] -> Some { major; minor; patch }
  | _ -> None

let next version change =
  match change with
  | Change.Breaking -> Ok { major = version.major + 1; minor = 0; patch = 0 }
  | Change.Minor ->
      Ok { major = version.major; minor = version.minor + 1; patch = 0 }
  | Change.Patch -> Ok { version with patch = version.patch + 1 }
  | Change.Unclear -> Error `Internal_error
