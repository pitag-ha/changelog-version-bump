type t = Breaking | Minor | Patch | Unclear

type tag = Tagged_as of t | Changed_header

let header_table =
  [
    ("Added", Tagged_as Minor);
    ("Changed", Changed_header);
    ("Deprecated", Tagged_as Minor);
    ("Fixed", Tagged_as Patch);
    ("Removed", Tagged_as Breaking);
    ("Security", Tagged_as Patch);
  ]

let tag_header header =
  List.fold_left
    (fun acc (known_header, tagging) ->
      if header = known_header then Ok tagging else acc)
    (Error header) header_table

let equal a b =
  match (a, b) with
  | Breaking, Breaking | Minor, Minor | Patch, Patch | Unclear, Unclear -> true
  | _ -> false

let is_greater_equal a b =
  match (a, b) with
  | Breaking, _ -> true
  | _, Breaking -> false
  | Minor, _ -> true
  | _, Minor -> false
  | Patch, _ -> true
  | _, Patch -> false
  | Unclear, Unclear -> true

let to_string change =
  match change with
  | Breaking -> "major change "
  | Minor -> "minor change"
  | Patch -> "patch"
  | Unclear -> "Unclear"
