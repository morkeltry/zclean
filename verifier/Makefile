all:
	ocamlbuild -use-ocamlfind -pkg yojson -pkg atdgen-runtime -pkg num -pkg cmdliner -pkg core -tag "ppx(ppx-jane -as-ppx)" -tag thread -tag debug -tag bin_annot -tag short_paths -cflags "-w A-4-33-40-41-42-43-34-44" -cflags -strict-sequence verifier.native

json-gen:
	atdgen -t merkle_tree.atd
	atdgen -j -j-std merkle_tree.atd

clean:
	rm -rf _build
	rm verifier.native
