(* Auto-generated from "merkle_tree.atd" *)
[@@@ocaml.warning "-27-32-35-39"]

type merkle_tree = Merkle_tree_t.merkle_tree

val write_merkle_tree :
  Bi_outbuf.t -> merkle_tree -> unit
  (** Output a JSON value of type {!merkle_tree}. *)

val string_of_merkle_tree :
  ?len:int -> merkle_tree -> string
  (** Serialize a value of type {!merkle_tree}
      into a JSON string.
      @param len specifies the initial length
                 of the buffer used internally.
                 Default: 1024. *)

val read_merkle_tree :
  Yojson.Safe.lexer_state -> Lexing.lexbuf -> merkle_tree
  (** Input JSON data of type {!merkle_tree}. *)

val merkle_tree_of_string :
  string -> merkle_tree
  (** Deserialize JSON data of type {!merkle_tree}. *)

