open! Import
open! Sequence

let%test_unit "of_lazy" =
  let t = range 0 100 in
  [%test_result: int list]
    (to_list (of_lazy (lazy t)))
    ~expect:(to_list t)

let%test_unit _ =
  let seq_of_seqs =
    unfold ~init:0 ~f:(fun i ->
      Some (unfold ~init:i ~f:(fun j -> Some ((i, j), j + 1)),
            i + 1))
  in
  [%test_result: (int * int) list]
    (to_list (take (interleave seq_of_seqs) 10))
    ~expect:[ 0,0
            ; 0,1 ; 1,1
            ; 0,2 ; 1,2 ; 2,2
            ; 0,3 ; 1,3 ; 2,3 ; 3,3
            ]

let%expect_test "round_robin vs interleave" =
  let list_of_lists =
    [ [1; 10; 100; 1000]
    ; [2; 20; 200]
    ; [3; 30]
    ; [4]
    ]
  in
  let list_of_seqs = List.map list_of_lists ~f:of_list in
  let seq_of_seqs = of_list list_of_seqs in
  print_s [%sexp (to_list (round_robin list_of_seqs) : int list)];
  [%expect {| (1 2 3 4 10 20 30 100 200 1_000) |}];
  print_s [%sexp (to_list (interleave seq_of_seqs) : int list)];
  [%expect {| (1 10 2 100 20 3 1_000 200 30 4) |}];
;;

let%test_unit _ =
  let evens = unfold ~init:0 ~f:(fun i -> Some (i, i + 2)) in
  let vowels = cycle_list_exn ['a';'e';'i';'o';'u'] in
  [%test_result: (int * char) list]
    (to_list (take (interleaved_cartesian_product evens vowels) 10))
    ~expect:[ 0,'a'
            ; 0,'e' ; 2,'a'
            ; 0,'i' ; 2,'e' ; 4,'a'
            ; 0,'o' ; 2,'i' ; 4,'e' ; 6,'a'
            ]

let%test_module "Sequence.merge*" =
  (module struct
    let%test_unit _ =
      [%test_eq: (int, int) Merge_with_duplicates_element.t list]
        (to_list
           (merge_with_duplicates
              (of_list [ 1; 2; ])
              (of_list [ 2; 3; ])
              (* Can't use Core_int.compare because it would be a dependency cycle. *)
              ~cmp:Int.compare))
        [ Left 1; Both (2, 2); Right 3; ]

    let%test_unit _ =
      [%test_eq: (int, int) Merge_with_duplicates_element.t list]
        (to_list
           (merge_with_duplicates
              (of_list [ 2; 1; ])
              (of_list [ 2; 3; ])
              ~cmp:Int.compare))
        [ Both (2, 2); Left 1; Right 3; ]

    let%test_unit _ =
      [%test_eq: (int * string) list]
        (to_list
           (merge
              (of_list [ (0, "A"); (1, "A"); ])
              (of_list [ (1, "B"); (2, "B"); ])
              ~cmp:(fun a b -> [%compare: int] (fst a) (fst b))))
        [ (0, "A"); (1, "A"); (2, "B"); ]
  end)

let%test _ = fold ~f:(+) ~init:0 (of_list [1; 2; 3; 4; 5]) = 15
let%test _ = fold ~f:(+) ~init:0 (of_list []) = 0

let (=) = Polymorphic_compare.(=)
let (<=) = Polymorphic_compare.(<=)

let%test _ =
  let test_equal l = to_list (of_list l) = l in
  test_equal [] && test_equal [1; 2; 3; 4; 5]
(* The test for longer list is after range *)

let%test _ = to_list (range 0 5) = [0;1;2;3;4]
let%test _ = to_list (range ~stop:`inclusive 0 5) = [0;1;2;3;4;5]
let%test _ = to_list (range ~start:`exclusive 0 5) = [1;2;3;4]
let%test _ = to_list (range ~stride:(-2) 5 1) = [5;3]

(* Test for to_list *)
let%test _ = to_list (range 0 5000) = List.range 0 5000

(* Functions used for testing by comparing to List implementation*)
let test_to_list s f g =
  to_list (f s) = g (to_list s)

(* For testing, we create a sequence which is equal to 1;2;3;4;5, but
   with a more interesting structure inside*)

let s12345 = map ~f:(fun x -> x / 2) (filter ~f:(fun x -> x % 2 = 0)
                                        (of_list [1;2;3;4;5;6;7;8;9;10]))

let sempty = filter ~f:(fun x -> x < 0) (of_list [1;2;3;4])

let test f g = test_to_list s12345 f g && test_to_list sempty f g

let%test _ =
  to_list s12345 = [1; 2; 3; 4; 5] &&
  to_list sempty = []

let%test _ =
  to_list (unfold_with s12345 ~init:1
             ~f:(fun s _ ->
               if s % 2 = 0 then
                 Skip (s+1)
               else if s = 5 then
                 Done
               else
                 Yield(s, s+1)))
  = [1;3]

let test_delay init =
  unfold_with_and_finish ~init
    ~running_step:(fun prev next ->
      Yield (prev, next))
    ~inner_finished:(fun x -> Some x)
    ~finishing_step:(fun prev ->
      match prev with
      | None -> Done
      | Some prev -> Yield (prev, None))

let%test _ =
  to_list (test_delay 0 s12345)
  = [0; 1; 2; 3; 4; 5]

let%test _ =
  to_list (test_delay 0 sempty)
  = [0]

let%test _ = to_list s12345 = [1; 2; 3; 4; 5]

let%test _ = test
               (map ~f:(fun i -> -i))
               (List.map ~f:(fun i -> -i))

let%test _ = test
               (mapi ~f:(fun i j -> j - 2 *i))
               (List.mapi ~f:(fun i j -> j - 2 *i))

let%test _ = test
               (filter ~f:(fun i -> i % 2 = 0))
               (List.filter ~f:(fun i -> i % 2 = 0))

let%test _ = length s12345 = 5 && length sempty = 0

let%test _ = find s12345 ~f:(fun x -> x = 3) = Some 3 &&
             find s12345 ~f:(fun x -> x = 7) = None

let%test _ = find_map s12345 ~f:(fun x -> if x = 3 then Some "a" else None) = Some "a" &&
             find_map s12345 ~f:(fun x -> if x = 7 then Some "a" else None) = None

let%test _ = find_mapi s12345 ~f:(fun _ x -> if x = 3 then Some "a" else None) = Some "a"
let%test _ = find_mapi s12345 ~f:(fun _ x -> if x = 7 then Some "a" else None) = None
let%test _ = find_mapi s12345 ~f:(fun i x -> if i + x >= 6 then Some (i,x) else None) = Some (3,4)

let%test _ = for_all sempty ~f:(fun _ -> false)
let%test _ = for_all s12345 ~f:(fun x -> x > 0)
let%test _ = not (for_all s12345 ~f:(fun x -> x < 5))

let%test _ = for_alli sempty ~f:(fun _ _ -> false)
let%test _ = for_alli s12345 ~f:(fun _ x -> x > 0)
let%test _ = not (for_alli s12345 ~f:(fun _ x -> x < 5))
let%test _ = for_alli s12345 ~f:(fun i x -> x = i+1)

let%test _ = not (exists sempty ~f:(fun _ -> assert false))
let%test _ = exists s12345 ~f:(fun x -> x = 5)
let%test _ = not (exists s12345 ~f:(fun x -> x = 0))

let%test _ = not (existsi sempty ~f:(fun _ _ -> assert false))
let%test _ = existsi s12345 ~f:(fun _ x -> x = 5)
let%test _ = not (existsi s12345 ~f:(fun _ x -> x = 0))
let%test _ = not (existsi s12345 ~f:(fun i x -> x <> i+1))

let%test _ =
  let l = ref [] in
  iter s12345 ~f:(fun x -> l := x::!l);
  !l = [5;4;3;2;1]

let%test _ = is_empty sempty
let%test _ = not (is_empty (of_list [1]))

let%test _ = mem s12345 1 ~equal:Int.equal
let%test _ = not (mem s12345 6 ~equal:Int.equal)

let%test _ = to_list empty = []

let%test _ = to_list (bind sempty ~f:(fun _ -> s12345)) = []
let%test _ = to_list (bind s12345 ~f:(fun _ -> sempty)) = []
let%test _ = to_list (bind s12345 ~f:(fun x -> of_list [x;-x])) = [1;-1;2;-2;3;-3;4;-4;5;-5]

let%test _ = to_list (return 1) = [1]

let%test _ = nth s12345 3 = Some 4
let%test _ = nth s12345 5 = None

let%test _ = hd s12345 = Some 1
let%test _ = hd sempty = None

let%test _ = tl sempty = None
let%test _ =  match tl s12345 with
  | Some l -> to_list l = [2;3;4;5]
  | None -> false

let%test _ = next sempty = None
let%test _ = match next s12345 with
  | Some (1,l) -> to_list l = [2;3;4;5]
  | _ -> false

let%test _ = to_list (filter_opt (of_list [None; Some 1; None ;Some 2; Some 3])) =
             [1;2;3]

let%test _ =
  let (l,r) = split_n s12345 2 in
  l = [1;2] && to_list r = [3;4;5]

let%test _ = to_list (chunks_exn s12345 2) = [[1;2];[3;4];[5]]

let%test _ = to_list (append s12345 s12345) = [1;2;3;4;5;1;2;3;4;5]
let%test _ = to_list (append sempty s12345) = [1;2;3;4;5]

let%test _ = to_list (zip s12345 sempty) = []
let%test _ = to_list (zip s12345 (of_list [6;5;4;3;2;1])) = [1,6;2,5;3,4;4,3;5,2]
let%test _ = to_list (zip s12345 (of_list ["a"])) = [1,"a"]

let%test _ = find_consecutive_duplicate s12345 ~equal:(=) = None
let%test _ = find_consecutive_duplicate (of_list [1;2;2;3;4;4;5]) ~equal:(=) = Some (2,2)

let%test _ = to_list
               (remove_consecutive_duplicates ~equal:(=) (of_list [1;2;2;3;3;3;3;4;4;5;6;6;7]))
             = [1;2;3;4;5;6;7]
let%test _ = to_list
               (remove_consecutive_duplicates ~equal:(=) s12345) = [1;2;3;4;5]

let%test _ = to_list (remove_consecutive_duplicates ~equal:(fun _ _ -> true) s12345) = [1]

let%test _ = to_list (init (-1) ~f:(fun _ -> assert false)) = []
let%test _ = to_list (init 5 ~f:Fn.id) = [0; 1; 2; 3; 4]

let%test _ = to_list (sub s12345 ~pos:4 ~len:10) = [5]
let%test _ = to_list (sub s12345 ~pos:1 ~len:2) = [2;3]
let%test _ = to_list (sub s12345 ~pos:0 ~len:0) = []

let%test _ = to_list (take s12345 2) = [1;2]
let%test _ = to_list (take s12345 0) = []
let%test _ = to_list (take s12345 9) = [1;2;3;4;5]

let%test _ = to_list (drop s12345 2) = [3;4;5]
let%test _ = to_list (drop s12345 0) = [1;2;3;4;5]
let%test _ = to_list (drop s12345 9) = []

let%test _ = to_list (take_while ~f:(fun x -> x < 3) s12345) = [1;2]

let%test _ = to_list (drop_while ~f:(fun x -> x < 3) s12345) = [3;4;5]

let%test _ = to_list (shift_right  (shift_right s12345 0) (-1)) = [-1;0;1;2;3;4;5]

let%test _ = to_list (intersperse ~sep:'a' (of_list [])) = []
let%test _ = to_list (intersperse ~sep:'a' (of_list ['b'])) = ['b']
let%test _ = to_list (intersperse ~sep:(-1) (take s12345 1)) = [1]
let%test _ = to_list (intersperse ~sep:0 s12345) = [1;0;2;0;3;0;4;0;5]

let%test _ = to_list (take (repeat 1) 3) = [1;1;1]

let%test _ = to_list (take (cycle_list_exn [1;2;3;4;5]) 7) = [1;2;3;4;5;1;2]

let%test _ =
  match cycle_list_exn [] with
  | exception Invalid_argument "Sequence.cycle_list_exn" -> true
  | _ -> false

let%test _ = to_list (cartesian_product (of_list ['a';'b']) s12345) =
             ['a',1;'a',2;'a',3;'a',4;'a',5;
              'b',1;'b',2;'b',3;'b',4;'b',5]

let%test _ =
  delayed_fold s12345 ~init:0.0
    ~f:(fun a i ~k ->
      if a <= 5.0 then
        k (a +. (Float.of_int i)) else
        a)
    ~finish:(fun _ -> assert false)
  = 6.0

let%expect_test "fold_m" =
  let module Simple_monad = struct
    type 'a t =
      | Return of 'a
      | Step of 'a t
    [@@deriving sexp_of]

    let return a = Return a

    let rec bind t ~f =
      match t with
      | Return a -> f a
      | Step t -> Step (bind t ~f)
    ;;

    let step = Step (Return ())
  end in
  fold_m ~bind:Simple_monad.bind ~return:Simple_monad.return s12345
    ~init:[]
    ~f:(fun acc n ->
      Simple_monad.bind Simple_monad.step ~f:(fun () ->
        Simple_monad.return (n :: acc)))
  |> printf !"%{sexp: int list Simple_monad.t}\n";
  [%expect {| (Step (Step (Step (Step (Step (Return (5 4 3 2 1))))))) |}]
;;

let%expect_test "iter_m" =
  iter_m ~bind:Generator.bind ~return:Generator.return s12345 ~f:Generator.yield
  |> Generator.run
  |> printf !"%{sexp: int t}\n";
  [%expect {| (1 2 3 4 5) |}]
;;

let%test _ =
  let num_computations = ref 0 in
  let t = memoize (unfold ~init:() ~f:(fun () -> Int.incr num_computations; None)) in
  iter t ~f:Fn.id;
  iter t ~f:Fn.id;
  !num_computations = 1

let%test _ = to_list (drop_eagerly s12345 0) = [1;2;3;4;5]
let%test _ = to_list (drop_eagerly s12345 2) = [3;4;5]
let%test _ = to_list (drop_eagerly s12345 5) = []
let%test _ = to_list (drop_eagerly s12345 8) = []

let compare_tests =
  [ [1; 2; 3] , [1; 2; 3] , 0
  ; [1; 2; 3] , []        , 1
  ; []        , [1; 2; 3] , -1
  ; [1; 2]    , [1; 2; 3] , -1
  ; [1; 2; 3] , [1; 2]    , 1
  ; [1; 3; 2] , [1; 2; 3] , 1
  ; [1; 2; 3] , [1; 3; 2] , -1 ]

(* this test has to use base OCaml library functions to avoid circular dependencies *)
let%test _ =
  List.for_all
    ~f:(fun b -> b)
    (List.map
       ~f:(fun (l1, l2, expected_res) ->
         compare Int.compare (of_list l1) (of_list l2) = expected_res)
       compare_tests)

let%test _ = folding_map (of_list [1;2;3;4]) ~init:0
               ~f:(fun acc x -> let y = acc+x in y,y) |> to_list = [1;3;6;10]
let%test _ = folding_map empty ~init:0
               ~f:(fun acc x -> let y = acc+x in y,y) |> is_empty
let%test _ = folding_mapi (of_list [1;2;3;4]) ~init:0
               ~f:(fun i acc x -> let y = acc+i*x in y,y) |> to_list = [0;2;8;20]
let%test _ = folding_mapi empty ~init:0
               ~f:(fun i acc x -> let y = acc+i*x in y,y) |> is_empty

let%expect_test _ =
  let xs = init 3 ~f:Fn.id |> Generator.of_sequence in
  let ( @ ) xs ys = Generator.bind xs ~f:(fun () -> ys) in
  (xs @ xs @ xs @ xs @ xs)
  |> Generator.run
  |> [%sexp_of: int t]
  |> print_s;
  [%expect {|
    (0 1 2 0 1 2 0 1 2 0 1 2 0 1 2) |}]
;;

let%test_module "group" =
  (module struct
    let%test _ =
      of_list [1; 2; 3; 4]
      |> group ~break:(fun _ x -> Int.equal x 3)
      |> [%compare.equal: int list t] (of_list [[1; 2]; [3; 4]])
    ;;

    let%test _ =
      group empty ~break:(fun _ -> assert false)
      |> [%compare.equal: unit list t] empty
    ;;

    let mis = of_list ['M';'i';'s';'s';'i';'s';'s';'i';'p';'p';'i']
    ;;

    let equal_letters =
      of_list [['M'];['i'];['s';'s'];['i'];['s';'s'];['i'];['p';'p'];['i']]
    ;;

    let single_letters = of_list [['M';'i';'s';'s';'i';'s';'s';'i';'p';'p';'i']]
    ;;

    let%test _ =
      group ~break:Char.(<>) mis
      |> [%compare.equal: char list t] equal_letters
    ;;

    let%test _ =
      group ~break:(fun _ _ -> false) mis
      |> [%compare.equal: char list t] single_letters
    ;;
  end)
