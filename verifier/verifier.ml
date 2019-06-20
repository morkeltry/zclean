open Merkle

let string_to_bigint =
  let open Big_int in
  let open Core in
  String.foldi ~f:(fun i acc c -> (mult_big_int (shift_left_big_int unit_big_int (8 * i))  (big_int_of_int (int_of_char c)))) ~init:zero_big_int

let bigint_to_bits n =
  let open Big_int in
  let rec h n =
    let q, r = quomod_big_int n (big_int_of_int 2) in
    if compare_big_int q zero_big_int = 0 then
      [int_of_big_int r]
    else
      (int_of_big_int r) :: h q
  in
  List.rev (h n)

let hash n = pedersen_hash n ""

let tree_height = 4

let read_tree () =
  let open Yojson in
  let open Core in
  let t = In_channel.read_all "tree.json" in
  let buf = Bi_outbuf.create 100 in
  let lexer_state = init_lexer ~buf:buf ~lnum:0 ~fname:"" () in
  let lexbuf = Lexing.from_string t in
  Merkle_tree_j.read_merkle_tree lexer_state lexbuf

let write_tree t =
  let buf = Bi_outbuf.create 100 in
  let _ = Merkle_tree_j.write_merkle_tree buf t in
  Core_kernel.Out_channel.write_all "tree.json" ~data:(Bi_outbuf.contents buf)

let make_initial_tree () =
  let secret = "secret10" in
  let r = string_to_bigint secret in
  Printf.printf "Secret: %s\n" (Big_int.string_of_big_int r);
  let cm = hash secret in
  let t = create_tree cm tree_height in
  write_tree t

let get_path root pos =
  let t = read_tree () in
  let current_root = Merkle.get_root t in
  if root = current_root then
    let hashes = Merkle.get_witness t tree_height (Int64.of_int pos) in
    Printf.printf "[%s]\n" @@ String.concat ", " (List.map (fun x -> Printf.sprintf "\"%s\"" x) hashes)
  else
    Printf.printf "Error: given root doesn't match with actual root"

let make_commitment value flag r =
  Printf.printf "%s\n" (hash (r ^ flag ^ value))

let make_nullifier value flag sk =
  Printf.printf "%s\n" @@ hash @@ (hash (sk ^ flag ^ value)) ^ sk

let add_commitment cm =
  let t = read_tree () in
  let pos = Int64.of_int (Merkle.get_number_of_elements t) in
  let t = Merkle.insert_leaf t cm tree_height pos in
  write_tree t

let () =
  let open Cmdliner in

  let init_tree_t = Term.(const make_initial_tree $ const ()), Term.info "init-tree" in

  let root = Arg.(value & pos 0 string "" & info []) in
  let pos = Arg.(value & pos 1 int 0 & info []) in
  let get_path_t = Term.(const get_path $ root $ pos), Term.info "get-path" in

  let v = Arg.(value & pos 0 string "" & info []) in
  let flag = Arg.(value & pos 1 string "" & info []) in
  let r = Arg.(value & pos 2 string "" & info []) in
  let make_commitment_t = Term.(const make_commitment $ v $ flag $ r), Term.info "make-cm" in
  let make_nullifier_t = Term.(const make_nullifier $ v $ flag $ r), Term.info "make-nullifier" in

  let cm = Arg.(value & pos 0 string "" & info []) in
  let add_commitment_t = Term.(const add_commitment $ cm), Term.info "add-cm" in

  let cmds = [init_tree_t; get_path_t; make_commitment_t; make_nullifier_t; add_commitment_t] in
  Term.(exit @@ eval_choice init_tree_t cmds)

