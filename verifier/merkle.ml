type hash = string

let uncommitted () = "0"

let pow a b =
  let rec pow' a x n =
    if n = 0L then a else pow' (Int64.mul a (if Int64.rem n 2L = 0L then 1L else x)) (Int64.mul x x) (Int64.div n 2L) in
  pow' 1L a b

type merkle_tree =
  | Leaf of hash
  | Node of (hash*merkle_tree*merkle_tree)
  | PartialNode of (hash * merkle_tree)

let pedersen_hash (a: string) (b: string) =
  let inp = Unix.open_process_in ("lib/crypto_util/crypto_util.exe pedersen " ^ a ^ b) in
  let r = Core.In_channel.input_lines inp in
  Core.In_channel.close inp;
  match Core_kernel.List.hd r with
  | Some digest -> (* Printf.printf "%s hashed to %s\n" (a^b) digest; *) digest
  | None -> failwith (Printf.sprintf "Hash error: %s\n" (a^b))

let unco depth =
  let uncom = Array.make depth (uncommitted()) in
  Array.iteri
    (fun i x -> if i < depth-1 then uncom.(i+1) <- pedersen_hash x x;)
    uncom;
  uncom

let create_tree x depth =
  assert(depth>=0);
  let uncom = unco depth in
  let rec aux tree i =
    if i >= depth then tree else
      match tree with
      | PartialNode(hash, l) -> aux (PartialNode((pedersen_hash hash uncom.(i)),PartialNode(hash,l))) (i+1)
      | Leaf(hash) -> aux (PartialNode((pedersen_hash hash uncom.(i)),Leaf(hash))) (i+1)
      | _ -> assert false
  in
  aux (Leaf(x)) 0

let get_root (tree : merkle_tree) =
  match tree with
  | Node(h,_,_) -> h
  | PartialNode(h,_) -> h
  | Leaf(h) -> h

let insert_leaf (tree : merkle_tree) x depth (pos : int64) =
  assert (pos >= 0L);
  assert  (pos <= pow 2L (Int64.of_int depth));
  let uncom = unco depth in

  let get_height pos =
    let rec aux i height =
      if ((Int64.logand pos (pow 2L (Int64.of_int (63-i)))) = 0L) && i>=0 then
        aux (i-1) (height+1) else
        height
    in
    aux 63 0
  in
  let height = get_height pos in

  let to_ins = create_tree x height in

  let mix i t1 t2 = match t1,t2 with
    | Leaf(h1),Leaf(h2) -> Node(pedersen_hash h1 h2, Leaf(h1), Leaf(h2))
    | PartialNode(h1,l1), PartialNode(h2,l2) -> Node(pedersen_hash h1 h2, PartialNode(h1,l1), PartialNode(h2,l2))
    | Node(h1,l1,r), PartialNode(h2,l2) -> Node(pedersen_hash h1 h2, Node(h1,l1,r), PartialNode(h2,l2))
    | Node(h1,l1,r1), Node(h2,l2,r2) -> Node(pedersen_hash h1 h2, Node(h1,l1,r1), Node(h2,l2,r2))
    | _ -> assert false
  in

  let rec propagate tree i =
    if i <= height+1 then begin
      match tree with
      | PartialNode(_,l) -> mix (i-1) l to_ins
      | _ -> assert false
    end
    else begin
      match tree with
      | Node(_,l,r) -> mix (i-1) l (propagate r (i-1))
      | PartialNode(_,l) -> let l2 = propagate l (i-1) in PartialNode(pedersen_hash (get_root l2) uncom.(i-1), l2)
      | _ -> assert false
    end
  in
  propagate tree depth

let get_witness (tree : merkle_tree) depth (pos : int64) =

  (*not sure what happens when pos overflow *)
  assert (pos >= 0L);
  (*Check that the position is not too big fro the tree*)
  assert  (pos <= pow 2L (Int64.of_int depth));
  (*get the default values at all the hight*)
  let uncom = unco depth in
  (* get the bits of position and put them in a boolean array
     These bits represent whether the neighbourh in the authentication path is left or right*)
  let get_bits pos =
    let res = Array.make 64 true in
    let rec loop pos i =
      if i < 64 then
        begin
          res.(63-i) <- not ((Int64.logand pos (pow 2L (Int64.of_int i))) = 0L) ;
          loop pos (i+1)
        end
    in
    loop pos 0;
    res
  in
  let array_pos = get_bits pos in

  (*get the niehgbourgh hashes*)
  let get_hashes array =
    let res = Array.make depth (String.make 32 '0') in
    let rec aux i tree =
      match tree with
      | Node(_, l, r) ->
          begin
            if array.(64-depth+i) then
              begin
                res.(i) <- get_root l;
                aux (i+1) r;
              end
            else
              begin
                res.(i) <- get_root r;
                aux (i+1) l;
              end
          end
      | PartialNode(_,l) ->
          begin
            if not array.(64-depth+i) then
              begin
                res.(i) <- uncom.(depth-1-i);
                aux (i+1) l;
              end
            else
              assert false
          end
      | Leaf(_) -> ();
    in
    aux 0 tree;
    res
  in
  let hashes = get_hashes array_pos in
  String.concat "" (Array.to_list hashes)

let () =
  let t = create_tree "ab" 4 in
  let t = insert_leaf t "bc" 4 0L in
  Printf.printf "%s\n" (get_witness t 4 0L)
