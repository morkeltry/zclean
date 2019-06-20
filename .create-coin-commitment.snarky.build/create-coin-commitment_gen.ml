open Snarky
open Snarky.Snark
module Impl =
  Snarky.Snark.Run.Make(Snarky.Backends.Bn128.Default)(Core_kernel.Unit)
open Impl
include
  struct
    type _ Snarky.Request.t +=  
      | Base_point: (Field.Constant.t * Field.Constant.t) Request.t 
  end
module Extended_lib =
  struct
    include
      struct
        type 'a quadruple = ('a * 'a * 'a * 'a)
        type 'a quadruple_var = ('a * 'a * 'a * 'a)
      end
    include
      struct
        type 'a triple = ('a * 'a * 'a)
        type 'a triple_var = ('a * 'a * 'a)
      end
    include
      struct type 'a double = ('a * 'a)
             type 'a double_var = ('a * 'a) end
    let max_int32 = 4294967295
    module UInt32 =
      struct
        let length = 32
        include struct type t = bool array
                       type var = Boolean.var array end
        let (xor : var -> var -> var) =
          fun t1 -> fun t2 -> Array.map2 Boolean.(lxor) t1 t2
        let (zero : var) = Array.init length (fun _ -> Boolean.false_)
        let ceil_log2 =
          loop
            (fun self ->
               fun n -> match n with | 0 -> 0 | _ -> 1 + (self (n / 2)))
        let take n xs =
          let (xs, _) =
            List.fold_left
              (fun (xs, k) ->
                 fun x ->
                   match k >= n with
                   | true -> (xs, k)
                   | false -> ((x :: xs), (k + 1))) ([], 0) xs in
          List.rev xs
        let (sum : var list -> var) =
          fun xs ->
            let (max_bit_length : int) =
              ceil_log2 ((List.length xs) * max_int32) in
            let xs_sum =
              List.fold_left
                (fun acc ->
                   fun x -> Field.(+) (Field.of_bits (Array.to_list x)) acc)
                (Field.constant (Field.Constant.of_string "0")) xs in
            (take 32 (Field.to_bits ~length:max_bit_length xs_sum)) |>
              Array.of_list
        let (rotr : var -> int -> var) =
          fun t ->
            fun by -> Array.init length (fun i -> t.((i + by) mod length))
        let int_get_bit (n : int) (i : int) =
          match (n lsr i) land 1 with
          | 1 -> Boolean.true_
          | _ -> Boolean.false_
        let (of_int : int -> var) =
          fun n ->
            (loop
               (fun self ->
                  fun (i, acc) ->
                    match i with
                    | 32 -> acc
                    | _ -> self ((i + 1), ((int_get_bit n (31 - i)) :: acc)))
               (0, []))
              |> Array.of_list
      end
    module Blake2 =
      struct
        let r1 = 16
        let r2 = 12
        let r3 = 8
        let r4 = 7
        let mixing_g v a b c d x y =
          let (=) i t = v.(i) <- t in
          let (!) = Array.get v in
          let sum = UInt32.sum in
          let xorrot t1 t2 k = UInt32.rotr (UInt32.xor t1 t2) k in
          a = (sum [!a; !b; x]);
          d = (xorrot (!d) (!a) r1);
          c = (sum [!c; !d]);
          b = (xorrot (!b) (!c) r2);
          a = (sum [!a; !b; y]);
          d = (xorrot (!d) (!a) r3);
          c = (sum [!c; !d]);
          b = (xorrot (!b) (!c) r4)
        let iv =
          Array.map UInt32.of_int
            (Array.of_list
               [1779033703;
               3144134277;
               1013904242;
               2773480762;
               1359893119;
               2600822924;
               528734635;
               1541459225])
        let sigma =
          (Array.of_list
             [[0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15];
             [14; 10; 4; 8; 9; 15; 13; 6; 1; 12; 0; 2; 11; 7; 5; 3];
             [11; 8; 12; 0; 5; 2; 15; 13; 10; 14; 3; 6; 7; 1; 9; 4];
             [7; 9; 3; 1; 13; 12; 11; 14; 2; 6; 5; 10; 4; 0; 15; 8];
             [9; 0; 5; 7; 2; 4; 10; 15; 14; 1; 11; 12; 6; 8; 3; 13];
             [2; 12; 6; 10; 0; 11; 8; 3; 4; 13; 7; 5; 15; 14; 1; 9];
             [12; 5; 1; 15; 14; 13; 4; 10; 0; 7; 6; 3; 9; 2; 8; 11];
             [13; 11; 7; 14; 12; 1; 3; 9; 5; 0; 15; 4; 8; 6; 2; 10];
             [6; 15; 14; 9; 11; 3; 0; 8; 12; 2; 13; 7; 1; 4; 10; 5];
             [10; 2; 8; 4; 7; 6; 1; 5; 15; 11; 9; 14; 3; 12; 13; 0]])
            |> (Array.map Array.of_list)
        let splitu64 (u : Int64.t) =
          let low = Int64.logand u (Int64.of_int max_int32) in
          let high = Int64.shift_right u 32 in (low, high)
        let (for_ : int -> (int -> unit) -> unit) =
          fun n ->
            fun f ->
              loop
                (fun self ->
                   fun i ->
                     match i = n with
                     | true -> ()
                     | false -> (f i; self (i + 1))) 0
        open UInt32
        let compression h (m : var array) t f =
          let v = Array.append h iv in
          let (tlo, thi) = splitu64 t in
          v.(12) <- (xor (v.(12)) (of_int (Int64.to_int tlo)));
          v.(13) <- (xor (v.(13)) (of_int (Int64.to_int thi)));
          (match f with
           | false -> ()
           | true -> v.(14) <- (xor (v.(14)) (of_int max_int32)));
          for_ 10
            (fun i ->
               let s = sigma.(i) in
               let mix a b c d i1 i2 =
                 mixing_g v a b c d (m.(s.(i1))) (m.(s.(i2))) in
               mix 0 4 8 12 0 1;
               mix 1 5 9 13 2 3;
               mix 2 6 10 14 4 5;
               mix 3 7 11 15 6 7;
               mix 0 5 10 15 8 9;
               mix 1 6 11 12 10 11;
               mix 2 7 8 13 12 13;
               mix 3 4 9 14 14 15);
          for_ 8
            (fun i ->
               h.(i) <- (xor (h.(i)) (v.(i)));
               h.(i) <- (xor (h.(i)) (v.(i + 8))))
        let block_size_in_bits = 512
        let digest_length_in_bits = 256
        let pad_input bs =
          let n = Array.length bs in
          match n mod block_size_in_bits with
          | 0 -> bs
          | k ->
              Array.append bs
                (Array.create (block_size_in_bits - k) Boolean.false_)
        let concat_int32s (ts : var array) =
          let n = Array.length ts in
          Array.init (n * UInt32.length)
            (fun i -> (ts.(i / UInt32.length)).(i mod UInt32.length))
        let personalization = String.init 8 (fun _ -> char_of_int 0)
        let (blake2s : Boolean.var list -> Boolean.var list) =
          fun input ->
            let input = Array.of_list input in
            let p o =
              let c j = (int_of_char (personalization.[o + j])) lsl (8 * j) in
              (((c 0) + (c 1)) + (c 2)) + (c 3) in
            let h =
              Array.map UInt32.of_int
                (Array.of_list
                   [1779033703 lxor 16842752;
                   3144134277;
                   1013904242;
                   2773480762;
                   1359893119;
                   2600822924;
                   528734635 lxor (p 0);
                   1541459225 lxor (p 4)]) in
            let padded = pad_input input in
            let (blocks : var array array) =
              let n = Array.length padded in
              match n with
              | 0 ->
                  Array.of_list
                    [Array.create (block_size_in_bits / UInt32.length)
                       UInt32.zero]
              | _ ->
                  Array.init (n / block_size_in_bits)
                    (fun i ->
                       Array.init (block_size_in_bits / UInt32.length)
                         (fun j ->
                            Array.init UInt32.length
                              (fun k ->
                                 padded.(((block_size_in_bits * i) +
                                            (UInt32.length * j))
                                           + k)))) in
            for_ ((Array.length blocks) - 1)
              (fun i ->
                 compression h (blocks.(i))
                   (Int64.mul (Int64.add (Int64.of_int i) (Int64.of_int 1))
                      (Int64.of_int 64)) false);
            (let input_length_in_bytes = ((Array.length input) + 7) / 8 in
             compression h (blocks.((Array.length blocks) - 1))
               (Int64.of_int input_length_in_bytes) true;
             (concat_int32s h) |> Array.to_list)
        let string_to_bool_list s =
          List.init (8 * (String.length s))
            (fun i ->
               let c = int_of_char (s.[i / 8]) in
               let j = i mod 8 in ((c lsr j) land 1) = 1)
      end
    module Curve =
      struct
        include
          struct
            type 'a coefficients = {
              a: 'a ;
              b: 'a }
            let coefficients_typ __implicit1__ =
              ({
                 Typ.store =
                   (fun { a; b;_} ->
                      Typ.Store.bind (Typ.store __implicit1__ b)
                        ~f:(fun b ->
                              Typ.Store.bind (Typ.store __implicit1__ a)
                                ~f:(fun a -> Typ.Store.return { a; b })));
                 Typ.read =
                   (fun { a; b;_} ->
                      Typ.Read.bind (Typ.read __implicit1__ b)
                        ~f:(fun b ->
                              Typ.Read.bind (Typ.read __implicit1__ a)
                                ~f:(fun a -> Typ.Read.return { a; b })));
                 Typ.alloc =
                   (Typ.Alloc.bind (Typ.alloc __implicit1__)
                      ~f:(fun b ->
                            Typ.Alloc.bind (Typ.alloc __implicit1__)
                              ~f:(fun a -> Typ.Alloc.return { a; b })));
                 Typ.check =
                   (fun { a; b;_} ->
                      make_checked
                        (fun () ->
                           Typ.check __implicit1__ b;
                           Typ.check __implicit1__ a;
                           ()))
               } : ('a2 coefficients, 'a1 coefficients) Typ.t)
          end
        open Field
        include
          struct
            type t = Field.Constant.t double
            type var = Field.t double_var
          end
        let div_unsafe x y =
          let (z : Field.t) =
            exists Field.typ
              ~compute:(fun () ->
                          Constant.(/) ((As_prover.read Field.typ) x)
                            ((As_prover.read Field.typ) y)) in
          assert_r1cs z y x; z
        let add_helper div (ax, ay) (bx, by) =
          let lambda = div (by - ay) (bx - ax) in
          let cx =
            exists Field.typ
              ~compute:(fun () ->
                          Constant.(-)
                            (Constant.square
                               ((As_prover.read Field.typ) lambda))
                            (Constant.(+) ((As_prover.read Field.typ) ax)
                               ((As_prover.read Field.typ) bx))) in
          let cy =
            exists Field.typ
              ~compute:(fun () ->
                          Constant.(-)
                            (Constant.( * )
                               ((As_prover.read Field.typ) lambda)
                               (Constant.(-) ((As_prover.read Field.typ) ax)
                                  ((As_prover.read Field.typ) cx)))
                            ((As_prover.read Field.typ) ay)) in
          assert_r1cs lambda lambda ((cx + ax) + bx);
          assert_r1cs lambda (ax - cx) (cy + ay);
          (cx, cy)
        let add_unsafe = add_helper div_unsafe
        let add = add_helper (/)
        let double (x, y) =
          let xy = x * y in
          let xx = x * x in
          let yy = y * y in
          let a =
            ((Field.constant (Field.Constant.of_string "2")) * xy) /
              (xx + yy) in
          let b =
            (yy - xx) /
              (((Field.constant (Field.Constant.of_string "2")) - xx) - yy) in
          (a, b)
        module Assert =
          struct
            let on_curve { a; b;_} (x, y) =
              let fx = (x * ((x * x) + a)) + b in assert_r1cs y y fx
            let not_equal (x1, y1) (x2, y2) =
              Boolean.Assert.any
                [Boolean.not (equal x1 x2); Boolean.not (equal y1 y2)]
            let equal (x1, y1) (x2, y2) =
              Assert.equal x1 x2; Assert.equal y1 y2
          end
        let negate (x, y) =
          (x, ((Field.constant (Field.Constant.of_string "0")) - y))
        let scale coeffs (bs : Boolean.var list) (g : var) =
          let (base_point : var) =
            exists (Typ.( * ) Field.typ Field.typ)
              ~request:(fun () -> Base_point) in
          Assert.on_curve coeffs base_point;
          Assert.not_equal base_point g;
          (let (acc, _) =
             List.fold_left
               (fun (acc, two_i_g) ->
                  fun b ->
                    let acc =
                      Select.id (Select.tuple2 Select.field Select.field) b
                        ~then_:(add acc two_i_g) ~else_:acc in
                    let two_i_g = double two_i_g in (acc, two_i_g))
               (base_point, g) bs in
           add acc (negate base_point))
      end
    module Pedersen =
      struct
        module Digest =
          struct
            include struct type t = Field.Constant.t
                           type var = Field.t end
            let to_bits = Field.to_bits ~length:Field.size_in_bits
          end
        module Params =
          struct
            include
              struct
                type t =
                  (Field.Constant.t * Field.Constant.t) quadruple array
                type var = (Field.t * Field.t) quadruple_var array
              end
            let load path =
              let comma = char_of_int 44 in
              let semi_colon = char_of_int 59 in
              let read_pair s =
                match String.split_on_char comma s with
                | x::y::[] -> ((Field.of_string x), (Field.of_string y)) in
              let strs = Array.of_list (read_lines path) in
              Array.map
                (fun s ->
                   match List.map read_pair
                           (String.split_on_char semi_colon s)
                   with
                   | x1::x2::x3::x4::[] -> (x1, x2, x3, x4)) strs
          end
        let (transpose :
          'a double_var quadruple_var -> 'a quadruple_var double_var) =
          fun ((x0, y0), (x1, y1), (x2, y2), (x3, y3)) ->
            ((x0, x1, x2, x3), (y0, y1, y2, y3))
        let add_int = (+)
        open Field
        let lookup ((s0, s1, s2) : Boolean.var triple_var)
          (q : Curve.var quadruple_var) =
          let s_and = Boolean.(&&) s0 s1 in
          let (bool : Boolean.var -> Field.t) = Boolean.to_field in
          let lookup_one (a1, a2, a3, a4) =
            ((a1 + ((a2 - a1) * (bool s0))) + ((a3 - a1) * (bool s1))) +
              ((((a4 + a1) - a2) - a3) * (bool s_and)) in
          let (x_q, y_q) = transpose q in
          let y = lookup_one y_q in
          let neg_one =
            (Field.constant (Field.Constant.of_string "0")) -
              (Field.constant (Field.Constant.of_string "1")) in
          let s2 = bool s2 in
          let a0 = (Field.constant (Field.Constant.of_string "2")) * s2 in
          let a1 = (Field.constant (Field.Constant.of_string "1")) - a0 in
          let y = a1 * y in ((lookup_one x_q), y)
        let digest params (triples : Boolean.var triple_var list) =
          (match triples with
           | [] -> failwith "Cannot handle empty list"
           | t::ts ->
               let (_, (x, _y)) =
                 List.fold_left
                   (fun (i, acc) ->
                      fun t ->
                        let term = lookup t (params.(i)) in
                        ((add_int i 1), (Curve.add_unsafe acc term)))
                   (1, (lookup t (params.(0)))) ts in
               x : Digest.var)
        type 'a three =
          | Zero 
          | One of 'a 
          | Two of 'a * 'a 
        let group3 xs =
          let default = Boolean.false_ in
          let (ts, r) =
            List.fold_left
              (fun (ts, acc) ->
                 fun x ->
                   match acc with
                   | Zero -> (ts, (One x))
                   | One x0 -> (ts, (Two (x0, x)))
                   | Two (x0, x1) -> (((x0, x1, x) :: ts), Zero)) ([], Zero)
              xs in
          let ts =
            match r with
            | Zero -> ts
            | One x0 -> (x0, default, default) :: ts
            | Two (x0, x1) -> (x0, x1, default) :: ts in
          List.rev ts
        let (digest_bits : Params.var -> Boolean.var list -> Field.t) =
          fun params -> fun bs -> digest params (group3 bs)
      end
  end
open Extended_lib
let main (mh0 : Field.t) (nf : Field.t) () =
  let params = load_pedersen_params "./constants/bn128-params" in
  let hash_bits (pre_image : Boolean.var list) =
    Pedersen.digest_bits params pre_image in
  let hash_field (pre_image : Field.t) =
    Pedersen.digest_bits params (Field.to_bits pre_image) in
  let order_nodes (a : Field.t) (b_tuple : (Field.t * Boolean.var)) =
    let (b, lr_bit_b) = b_tuple in
    Select.id (Select.tuple2 Select.field Select.field) lr_bit_b
      ~then_:(a, b) ~else_:(b, a) in
  let hash_merkle_nodes (ordered_nodes_tuple : (Field.t * Field.t)) =
    let node1_bool = Field.to_bits (fst ordered_nodes_tuple) in
    let node2_bool = Field.to_bits (snd ordered_nodes_tuple) in
    hash_bits (node1_bool @ node2_bool) in
  let hash_commitment (secret : Field.t) (val1 : Field.t) (val2 : Field.t) =
    let secret_bool = Field.to_bits secret in
    let val1_bool = Field.to_bits val1 in
    let val2_bool = Field.to_bits val2 in
    let hashable = (secret_bool @ val1_bool) @ val2_bool in
    hash_bits hashable in
  let hash_nullifier_commitment (secret : Field.t) (n : Field.t) =
    let secret_bool = Field.to_bits secret in
    let n_bool = Field.to_bits n in
    let hashable = secret_bool @ n_bool in hash_bits (secret_bool @ n_bool) in
  let (r, v, flag, tree_threeple, r', flag', v') =
    exists
      (Typ.tuple7 Field.typ Field.typ Field.typ
         (Typ.tuple3 (Typ.( * ) Field.typ Boolean.typ)
            (Typ.( * ) Field.typ Boolean.typ)
            (Typ.( * ) Field.typ Boolean.typ)) Field.typ Field.typ Field.typ)
      ~compute:(fun () ->
                  let r::v::flag::l1_sib_string::l2_sib_string::l3_sib_string::r'::flag'::v'::[]
                    = read_lines "transfer_secrets" in
                  let sep = ",".[0] in
                  let l1_hash::l1_dir::[] =
                    String.split_on_char ((As_prover.read Typ.char) sep)
                      l1_sib_string in
                  let l1_sibling =
                    ((Field.Constant.of_string
                        ((As_prover.read Typ.string) l1_hash)),
                      (Stdlib.bool_of_string
                         ((As_prover.read Typ.string) l1_dir))) in
                  let l2_hash::l2_dir::[] =
                    String.split_on_char ((As_prover.read Typ.char) sep)
                      l2_sib_string in
                  let l2_sibling =
                    ((Field.Constant.of_string
                        ((As_prover.read Typ.string) l2_hash)),
                      (Stdlib.bool_of_string
                         ((As_prover.read Typ.string) l2_dir))) in
                  let l3_hash::l3_dir::[] =
                    String.split_on_char ((As_prover.read Typ.char) sep)
                      l3_sib_string in
                  let l3_sibling =
                    ((Field.Constant.of_string
                        ((As_prover.read Typ.string) l3_hash)),
                      (Stdlib.bool_of_string
                         ((As_prover.read Typ.string) l3_dir))) in
                  let r = Field.Constant.of_string r in
                  let v = Field.Constant.of_string v in
                  let flag = Field.Constant.of_string flag in
                  Field.Constant.print r;
                  (let r' = Field.Constant.of_string r' in
                   let v' = Field.Constant.of_string v' in
                   let flag' = Field.Constant.of_string flag' in
                   (r, v, flag, (l1_sibling, l2_sibling, l3_sibling), r',
                     flag', v'))) in
  let t = hash_commitment r v flag in
  let (l1_sibling, l2_sibling, l3_sibling) = tree_threeple in
  let level2_parent = hash_merkle_nodes (order_nodes t l3_sibling) in
  let level1_parent =
    hash_merkle_nodes (order_nodes level2_parent l2_sibling) in
  let calculated_root =
    hash_merkle_nodes (order_nodes level1_parent l1_sibling) in
  let n = hash_nullifier_commitment r t in
  assert_r1cs calculated_root (Field.constant (Field.Constant.of_string "1"))
    mh0;
  assert_r1cs v (Field.constant (Field.Constant.of_string "1")) v';
  assert_r1cs flag (Field.constant (Field.Constant.of_string "1")) flag';
  assert_r1cs n (Field.constant (Field.Constant.of_string "1")) nf
module Toplevel_param_module__ =
  struct
    type result = unit
    type computation = Field.t -> Field.t -> unit -> unit
    type public_input = Field.Constant.t -> Field.Constant.t -> unit
    let compute = main
    let public_input = let open Data_spec in [Field.typ; Field.typ]
    let read_input a =
      match a with
      | f_1::f_0::[] ->
          let open H_list in
            [Field.Constant.of_string f_1; Field.Constant.of_string f_0]
      | _ -> failwith "Wrong number of arguments: expected 2"
  end
module Toplevel_CLI_module__ =
  Snarky.Toplevel.Make(Impl)(Toplevel_param_module__)
let () = Toplevel_CLI_module__.main ()
