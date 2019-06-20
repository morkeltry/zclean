open Merkle

let () =
  let t = create_tree "ab" 4 in
  let t = insert_leaf t "bc" 4 0L in

  let buf = Bi_outbuf.create 100 in
  let _ = Merkle_tree_j.write_merkle_tree buf t in
  Core_kernel.Out_channel.write_all "tree.json" ~data:(Bi_outbuf.contents buf)
