## v0.11.1

- Fix 4.07 build (#52, fixes #47)

- Fix backtrace truncation problem (fix #44)

## v0.11.0

- Deprecated `Not_found`, people who need it can use `Caml.Not_found`, but its
  use isn't recommended.

- Added the `Sexp.Not_found_s` exception which will replace `Caml.Not_found` as
  the default exception in a future release.

- Document that `Array.find_exn`, `Array.find_map_exn`, and `Array.findi_exn`
  may throw `Caml.Not_found` _or_ `Not_found_s`.

- Document that `Hashtbl.find_exn` may throw `Caml.Not_found` _or_
  `Not_found_s`.

- Document that `List.find_exn`, and `List.find_map_exn` may throw
  `Caml.Not_found` _or_ `Not_found_s`.

- Document that `List.find_exn` may throw `Caml.Not_found` _or_ `Not_found_s`.

- Document that `String.lsplit2_exn`, and `String.rsplit2_exn` may throw
  `Caml.Not_found` _or_ `Not_found_s`.

- Added `Sys.backend_type`.

- Removed unnecessary unit argument from `Hashtbl.create`.

- Removed deprecated operations from `Hashtbl`.

- Removed `Hashable.t` constructors from `Hashtbl` and `Hash_set`, instead
  favoring the first-class module constructors.

- Removed `Container` operations from `Either.First` and `Either.Second`.

- Changed the type of `fold_until` in the `Container` interfaces. Rather than
  returning a `Finished_or_stopped_early.t` (which has also been removed), the
  function now takes a `finish` function that will be applied the result if `f`
  never returned a `Stop _`.

- Removed the `String_dict` module.

- Added a `Queue` module that is backed by an `Option_array` for efficient and
  (non-allocating) implementations of most operations.

- Added a `Poly` submodule to `Map` and `Set` that exposes constructors that
  use polymorphic compare.

- Deprecated `all_ignore` in the `Monad` and `Applicative` interfaces in favor
  of `all_unit`.

- Deprecated `Array.replace_all` in favor of `Array.map_inplace`, which is the
  standard name for that sort of operation within Base.

- Document that `List.find_exn`, and `List.find_map_exn` may throw
  `Caml.Not_found` _or_ `Not_found_s`.

- Make `~compare` a required argument to `List.dedup_and_sort`, `List.dedup`,
  `List.find_a_dup`, `List.contains_dup`, and `List.find_all_dups`.

- Removed `List.exn_if_dup`. It is still available in core_kernel.

- Removed "normalized" index operation `List.slice`. It is still available in
  core_kernel.

- Remove "normalized" index operations from `Array`, which incluced
  `Array.normalize`, `Array.slice`, `Array.nget` and `Array.nset`. These
  operations are still available in core_kernel.

- Added `Uniform_array` module that is just like an `Array` except guarantees
  that the representation array is not tagged with `Double_array_tag`, the tag
  for float arrays.

- Added `Option_array` module that allows for a compact representation of `'a
  optoin array`, which avoids allocating heap objects representing `Some a`.

- Remove "normalized" index operations from `String`, which incluced
  `String.normalize`, `String.slice`, `String.nget` and `String.nset`. These
  operations are still available in core_kernel.

- Added missing conversions between `Int63` and other integer types,
  specifically, the versions that return options.

- Added truncating versions of integer conversions, with a suffix of
  `_trunc`.  These allow fast conversions via bit arithmetic without
  any conditional failure; excess bits beyond the width of the output
  type are simply dropped.

- Added `Sequence.group`, similar to `List.group`.

- Reimplemented `String.Caseless.compare` so that it does not
  allocate.

- Added `String.is_substring_at string ~pos ~substring`.  Used it as
  back-end for `is_suffix` and `is_prefix`.

- Moved all remaining `Replace_polymorphic_compare` submodules from Base
  types and consolidated them in one place within `Import0`.

- Removed `(<=.)` and its friends.

- Added `Sys.argv`.

- Added a infix exponentation operator for int.

- Added a `Formatter` module to reexport the `Format.formatter` type and updated
  the deprecation message for `Format`.

## v0.10

(Changes that can break existing programs are marked with a "\*")

### Bugfixes

- Generalized the type of `Printf.ifprintf` to reflect OCaml's stdlib.

- Made `Sequence.fold_m` and `iter_m` respect `Skip` steps and explicitly bind
  when they occur.

- Changed `Float.is_negative` and `is_non_positive` on `NaN` to return `false`
  rather than `true`.

- Fixed the `Validate.protect` function, which was mistakenly raising exceptions.

### API changes

- Renamed `Map.add` as `set`, and deprecated `add`. A later feature will add
  `add` and `add_exn` in the style of `Hashtbl`.

- A different hash function is used to implement [Base.Int.hash].
  The old implementation was [Int.abs] but collision resistance is not enough,
  we want avalanching as well.
  The new function is an adaptation of one of the
  [Thomas Wang](http://web.archive.org/web/20071223173210/http://www.concentric.net/~Ttwang/tech/inthash.htm)
  hash functions to OCaml (63-bit integers), which results in reasonably good avalanching.


- Made `open Base` expose infix float operators (+., -., etc.).

* Renamed `List.dedup` to `List.dedup_and_sort`, to better reflect its existing behavior.

- Added `Hashtbl.find_multi` and `Map.find_multi`.

- Added function `Map.of_increasing_sequence` for constructing a `Map.t` from an
  ordered `Sequence.t`

- Added function `List.chunks_of : 'a t -> length : int -> 'a t t`, for breaking
  a list into chunks of equal length.

- Add to module `Random` numeric functions that take upper and lower inclusive
  bounds, e.g. `Random.int_incl : int -> int -> int`.

* Replaced `Exn.Never_elide_backtrace` with `Backtrace.elide`, a `ref` cell that
  determines whether `Backtrace.to_string` and `Backtrace.sexp_of_t` elide
  backtraces.

- Exposed infix operator `Base.( @@ )`.

- Exposed modules `Base.Continue_or_stop` and `Finished_or_stopped_early`, used
  with the `Container.fold_until` function.

- Exposed module types Base.T, T1, T2, and T3.

- Added `Sequence.Expert` functions `next_step` and
  `delayed_fold_step`, for clients that want to explicitly handle `Skip` steps.

- Added `Bytes` module.
  This includes the submodules `From_string` and `To_string` with blit
  functions.
  N.B. the signature (and name) of `unsafe_to_string` and `unsafe_of_string` are
  different from the one in the standard library (and hopefully more explicit).

- Add bytes functions to `Buffer`.
  Also added `Buffer.content_bytes`, the analog of `contents` but that returns
  `bytes` rather than `string`.

* Enabled `-safe-string`.

- Added function `Int63.of_int32`, which was missing.

* Deprecated a number of `String` mutating functions.

- Added module `Obj_array`, moved in from `Core_kernel`.

* In module type `Hashtbl.Accessors`, removed deprecated functions, moving them
  into a new module type, `Deprecated`.

- Exported `sexp_*` types that are recognized by `ppx_sexp_*` converters:
  `sexp_array`, `sexp_list`, `sexp_opaque`, `sexp_option`.

* Reworked the `Or_error` module's interface, moving the `Container.S` interface
  to an `Ok` submodule, and adding functions `is_ok`, `is_error`, and `ok` to
  more closely resemble the interface of the `Result` module.

- Removed `Int.O.of_int_exn`.

- Exposed `Base.force` function.

- Changed the deprecation warning for `mod` to recommend `( % )` rather than
  `Caml.( mod )`.

### Performance related changes

- Optimized `List.compare`, removing its closure allocation.

- Optimized `String.mem` to not allocate.

- Optimized `Float.is_negative`, `is_non_negative`, `is_positive`, and
  `is_non_positive` to avoid some boxing.

- Changed `Hashtbl.merge` to relax its equality check on the input tables'
  `Hashable.t` records, checking physical equality componentwise if the records
  aren't physically equal.

- Added `Result.combine_errors`, similar to `Or_error.combine_errors`, with a
  slightly different type.

- Added `Result.combine_errors_unit`, similar to `Or_error.combine_errors_unit`.

- Optimized the `With_return.return` type by adding the `[@@unboxed]` attribute.

- Improved a number of deprecation warnings.


## v0.9

Initial release.
