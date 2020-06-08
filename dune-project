(lang dune 2.5.1)
(name ochangelog)

(generate_opam_files true)
(source (github pitag-ha/ochangelog))
(maintainers "Sonja Heinze <sonjaleaheinze@gmail.com>")
(authors "Sonja Heinze <sonjaleaheinze@gmail.com>")

(package
 (name ochangelog)
 (synopsis "automize your changelog manipulation when releasing")
 (description "\
automize your changelog manipulation when releasing in one of the following two ways:\n\
- get a suggestion for what the next version number should be; make use of that, for example, in a script\n\
- bump your changelog by using a `dune alias` with a `diff` action attached and calling `dune promote`
")
 (depends base stdio rresult cmdliner unix))
(using mdx 0.1)
