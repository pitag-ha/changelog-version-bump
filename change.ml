type t = Breaking | Minor | Patch | Unclear

let is_greater_equal a b =
  match (a, b) with
  | Breaking, _ -> true
  | _, Breaking -> false
  | Minor, _ -> true
  | _, Minor -> false
  | Patch, _ -> true
  | _, Patch -> false
  | Unclear, Unclear -> true

let tag_header header =
  match header with
  | "Fixed" -> Some Patch
  | "Security" -> Some Patch
  | "Added" -> Some Minor
  | "Deprecated" -> Some Minor
  | "Removed" -> Some Breaking
  | "Changed" -> Some Unclear
  | _ -> None

let to_string change =
  match change with
  | Breaking -> "major change "
  | Minor -> "minor change"
  | Patch -> "patch"
  | Unclear -> "Unclear"
