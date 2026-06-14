(lang dune 3.23)

(name ask-me-anything)

(generate_opam_files true)

(source
 (github sheetsync/ask-me-anything))

(authors "James Cane <james@jamescane.com>")

(maintainers "James Cane <james@jamescane.com>")

(license MIT)

(documentation https://github.com/sheetsync/ask-me-anything#readme)

(package
 (name ask-me-anything)
 (synopsis "A small one-shot CLI wrapper for asking Codex questions")
 (description
  "Ask is a small helper CLI that turns a plain English command into a one-shot Codex exec run.")
 (depends
  (ocaml
   (>= 5.1))
  (cmdliner
   (>= 2.1.0))
  (yaml
   (>= 3.2.0)))
 (tags
  (codex cli ocaml agent)))
