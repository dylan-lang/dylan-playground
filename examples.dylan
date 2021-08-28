Module: dylan-playground

// Some collected examples to use in the playground.  This file is a bit
// unusual because of the long multi-line strings of the form #:string:|...|,
// each of which holds a full example. The entire file is one big vector.
// Adding a new example should ONLY require adding a new mapping to this table
// since the Examples menu will be generated from this.


define constant $default-example = "Hello World";

// A vector of #["Menu item name", example-code] vectors.  The order here is
// reflected in the Examples menu. To some extent they're ordered from simple
// to more complex.
define constant $examples
  = vector(vector("Hello World", #:string:|
format-out("Hello %s\n", "World")
|),

           vector("Fibonacci Closure", #:string:|
define method fib ()
  let a = 0;
  let b = 1;
  method ()
    let r = a + b;
    a := b;
    b := r;
    a
  end
end;

let f = fib();
for (i from 1 to 20) format-out("%= ", f()) end
|),


           vector("Factorial, recursive", #:string:|
// A recursive version of factorial using singleton method dispatch.
define method factorial (n == 0) 1 end;  // called when n = 0
define method factorial (n == 1) 1 end;  // called when n = 1
define method factorial (n)              // called for any other n
  n * factorial(n - 1)
end;

format-out("%d", factorial(10));

// Things to try:
// * Rewrite the code so it uses a single method instead of three. Which do you prefer?
// * Uncomment this line and fix the resulting errors:
//   define generic factorial (n :: <integer>) => (n :: <integer>);
|),

           vector("Factorial, iterative", #:string:|
define function factorial (n :: <integer>) => (factorial :: <integer>)
  iterate loop (n = n, total = 1)
    if (n < 2)
      total                     // return total from the if/loop/function
    else
      loop(n - 1, n * total)    // tail call = iteration
    end
  end
end function;

format-out("%d", factorial(10));

// Try rewriting it using a more traditional "for" loop!
|),

           vector("for loop", #:string:|
// The "for" loop may have multiple iteration clauses. The first
// one to terminate ends the iteration.

for (i from 1,
     c in "abcdef",
     until: c = 'e')
  format-out("%d: %s\n", i, c);
end;
|),

           vector("Classes", #:string:|
// Classes are the primary way to build data structures in Dylan.
// Slots are accessed via normal function calls.

define class <account> (<object>)
  constant slot account-id :: <integer>,
    required-init-keyword: id:;
  constant slot account-name :: <string>,
    required-init-keyword: name:;
  slot account-balance :: <integer> = 0;
end;

let a = make(<account>, id: 1, name: "Zippy");
account-balance(a) := 500;
format-out("%s (#%d) balance = %d",
           account-name(a), account-id(a), account-balance(a));
|),

           vector("Error handling", #:string:|
block ()
  format-out("%=", floof)
exception (err :: <error>)
  format-out("error: %s", err)
end;

// Things to notice/try:
// * The Dylan compiler produces a functioning executable despite serious errors.
//   This is so that you can do interactive development without adding stubs for
//   unfinished code. (Of course running the unfinished code causes an error.)
// * Replace "floof" with other kinds of run-time errors.
|),

           vector("List subclasses", #:string:{
// Display a class's subclasses via indentation while
// avoiding repetition due to multiple inheritance.

define function list-subclasses (class :: <class>)
  let seen = make(<stretchy-vector>);
  iterate loop (class = class, indent = "")
    let seen? = member?(class, seen);
    let subclasses = direct-subclasses(class);
    let extra = seen? & ~empty?(subclasses) & " (see above)";
    format-out("%s%s%s\n", indent, class, extra | "");
    if (~seen?)
      add!(seen, class);
      for (subclass in subclasses)
        loop(subclass, concatenate("    ", indent));
      end
    end if;
  end iterate;
end function;

list-subclasses(<collection>);

// Things to try:
// * Change <collection> to <number>, <object>, or object-class(42).
// * Make list-subclasses(42) work. I.e., passing an integer or string.
}),
           vector("Graph Subclasses", #:string:|
// Generate DOT language to represent a subclass graph.
// One quick way to view the graph is to paste it here:
// https://dreampuf.github.io/GraphvizOnline/

define function dot (class :: <class>)
  let seen = make(<stretchy-vector>);
  format-out("digraph G {\n");
  iterate loop (class = class)
    let seen? = member?(class, seen);
    let subclasses = direct-subclasses(class);
    if (~seen?)
      add!(seen, class);
      for (subclass in subclasses)
        format-out("  %= -> %=;\n", debug-name(class), debug-name(subclass));
        loop(subclass);
      end;
    end;
  end iterate;
  format-out("}\n");
end function;

dot(<number>)
|),
           vector("Macros", #:string:|
// Macros define new syntax. Much of core Dylan syntax, such as "for"
// and "case", are implemented with macros. For example, suppose you
// would rather write
//   inc!(x)         or    inc!(x, 2)
// instead of
//   x := x + 1      or    x := x + 2

define macro inc!
    { inc!(?var:name) } => { inc!(?var, 1) }
    { inc!(?var:name, ?val:expression) } => { ?var := ?var + ?val }
end;

let x = 0;
inc!(x);
inc!(x, 10);
format-out("x = %d\n", x);

// See https://opendylan.org/articles/macro-system/index.html to
// get a sense of the full power of macros.
|),
           vector("Quicksort", #:string:|
// A mostly dynamically typed version of quicksort.

define method quicksort!
    (v :: <sequence>) => (v :: <sequence>)
  local
    method exchange (m, n) => ()
      let t = v[m];
      v[m] := v[n];
      v[n] := t
    end,
    method partition (lo, hi, x) => (i, j)
      let i = for (i from lo to hi, while: v[i] < x)
              finally i
              end;
      let j = for (j from hi to lo by -1, while: x < v[j])
              finally j
              end;
      if (i <= j)
        exchange(i, j);
        partition(i + 1, j - 1, x)
      else
        values(i, j)
      end
    end,
    method qsort (lo, hi) => ()
      if (lo < hi)
        let (i, j) = partition(lo, hi, v[round/(lo + hi, 2)]);
        qsort(lo, j);
        qsort(i, hi)
      end
    end;
  qsort(0, v.size - 1);
  format-out("%=\n", v);
  v
end method;

quicksort!(vector("my", "dog", "has", "fleas"));
quicksort!(list(4, 2, 900, -6));
|));  // end define constant $examples

define function find-example (name)
  let k = find-key($examples, method (v) v.first = name end);
  k & $examples[k]
end;

define function find-example-code (name)
  let v = find-example(name);
  v & strip-left(v[1])
end;
