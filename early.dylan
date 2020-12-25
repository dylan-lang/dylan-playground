Module: dylan-playground
Synopsis: Code that needs to defined early because several other files depend on it.


// Make #:string:|...| syntax work.
define function string-parser (s) => (s) s end;

