(* Auto-generated from "merkle_tree.atd" *)
              [@@@ocaml.warning "-27-32-35-39"]

type merkle_tree = [
    `Leaf of string
  | `Node of (string * merkle_tree * merkle_tree)
  | `PartialNode of (string * merkle_tree)
]
