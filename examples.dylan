Module: web-playground

// Some collected examples to use in the playground.  This file is a bit
// unusual because of the long multi-line strings of the form #:string:|...|,
// each of which holds a full example. The entire file is one big vector.
// Adding a new example should ONLY require adding a new mapping to this table
// since the Examples menu will be generated from this.


define constant $hello-world = "Hello World";

// A vector of #["Menu item name", example-code] vectors.  The order here is
// reflected in the Examples menu. To some extent they're ordered from simple
// to more complex.
define constant $examples
  = vector(vector($hello-world, #:string:|
format-out("Hello %s\n", "World")
|),


           vector("Factorial (recursive)", #:string:|
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

           vector("Factorial (iterative)", #:string:|
define function factorial (n :: <integer>) => (factorial :: <integer>)
  iterate loop (n = n, total = 1)
    if (n < 2)
      total                     // return total from the if>loop>function
    else
      loop(n - 1, n * total)    // tail call = iteration
    end
  end
end function;

format-out("%d", factorial(10));
|),

           vector("for loop", #:string:|
for (i from 1,
     c in "abcdef",
     until: c = 'e')
  format-out("%d: %s\n", i, c);
end;

// Things to try:
// * Write the same loop with the iterate macro. Use Library Docs index ->
|),

           vector("Classes", #:string:|
define abstract class <named-thing> (<object>)
  constant slot name :: <string>, required-init-keyword: name:;
end;

define class <person> (<named-thing>)
  slot age :: <integer> = 0, init-keyword: age:;
end;

let p = make(<person>, name: "Dylan");
format-out("Name: %s\nAge: %d\n", p.name, p.age);

let p = make(<person>, name: "Thomas", age: 23);
format-out("Name: %s\nAge: %d\n", p.person-name, p.person-age);

p.person-age := 24;
format-out("Name: %s\nAge: %d\n", p.person-name, p.person-age);

// Things to try:
// * Use multiple inheritance to implement age via an <aged-thing> abstract class.
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

           vector("Show type hierarchy", #:string:|
// This displays the type hierarchy of a class via indentation
// while avoiding repetition due to multiple inheritance.        
define function show-type-hierarchy (class :: <class>)
  let seen = make(<stretchy-vector>);
  iterate loop (class = class, indent = "")
    let seen? = member?(class, seen);
    let subclasses = direct-subclasses(class);
    let extra = if (seen? & ~empty?(subclasses))
                  "  // (see above)"
                else
                  ""
                end;
    format-out("%s%s%s\n", indent, class, extra);
    if (~seen?)
      add!(seen, class);
      for (subclass in subclasses)
        loop(subclass, concatenate("    ", indent));
      end
    end if;
  end iterate;
end function;

show-type-hierarchy(<collection>);

// Things to try:
// * Change <collection> to <number>, <object>, or object-class(42).
// * Make show-type-hierarchy(42) work. I.e., passing an integer or string.
|),

           // TODO: this code could be improved!
           vector("Roman numerals", #:string:|
define constant $limits
  = #[1000, 900, 500, 400, 100,  90,   50,  40,   10,  9,    5,   1];

define constant $romans
  = #["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "I"];

define method decimal-to-roman (num)
  while (num > 0)
    block (next)
      for (limit in $limits,
           roman in $romans)
        if (num >= limit)
          format-out("%s", roman);
          num := num - limit;
          next();
        end;
      end;
    end block;
  end while;
end method;

decimal-to-roman(1234);
|),
           vector("Macros", #:string:|
// Macros define new syntax. For example, let's say you find "if (test) this
// else that end" a bit wordy for otherwise short conditionals. This macro
// defines iff(test, this, that) as an alternative syntax.
define macro iff
    { iff(?test:expression, ?true:expression, ?false:expression) } // pattern
 => { if (?test) ?true else ?false end } // generated code
end;

iff(#t, format-out("true"), format-out("false"));

// Things to notice/try:
// * Only the first argument is evaluated, unlike if you defined "iff" as a function.
// * Make it work without an ELSE part: iff(#t, this)
//   Hint: duplicate the pattern and generated code lines and then modify them.
|));  // end define constant $examples

define function find-example (name)
  let k = find-key($examples, method (v) v.first = name end);
  k & $examples[k]
end;

define function find-example-code (name)
  let v = find-example(name);
  v & strip-left(v[1])
end;
