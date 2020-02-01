Module: web-playground

// Some collected examples to use in the playground.
// TODO: add to the tests, to be sure they compile and run.

define function show-class-hierarchy (class :: <class>)
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

// Also try <number> and for all the gory internal classes try <object>!
// Note that many of the classes in the output may not be accessible from this module.
show-class-hierarchy(<collection>)

// --------------------------------

define constant $decimals
  = vector(1000, 900, 500, 400, 100,  90,   50,  40,   10,  9,    5,   1);

define constant $romans
  = vector("M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "I");

define method decimal-to-roman ()
  format-out("Enter a number: ");
  force-out();
  let num = string-to-integer(read-line(*standard-input*));
  while (num > 0)
    block (next)
      for (decimal in $decimals,
           roman in $romans)
        if (num >= decimal)
          format-out("%s", roman);
          num := num - decimal;
          next();
        end;
      end;
    end block;
  end while;
  format-out("\n\n");
end method;

decimal-to-roman();

// --------------------------------

define table *led-table*
  = {
     '0' => " _  ,| | ,|_| ",
     '1' => "  ,| ,| ",
     '2' => " _  , _| ,|_  ",
     '3' => "_  ,_| ,_| ",
     '4' => "    ,|_| ,  | ",
     '5' => " _  ,|_  , _| ",
     '6' => " _  ,|_  ,|_| ",
     '7' => "_   , |  , |  ",
     '8' => " _  ,|_| ,|_| ",
     '9' => " _  ,|_| , _| ",
     };

define method led-numbers ()
  format-out("Enter a number: ");
  force-out();
  let num = read-line(*standard-input*);
  let line1 = "";
  let line2 = "";
  let line3 = "";
  for (char in num)
    let line = *led-table*[char];
    let val = split(line, ',');
    line1 := concatenate!(line1, val[0]);
    line2 := concatenate!(line2, val[1]);
    line3 := concatenate!(line3, val[2]);
  end;
  format-out("%s\n", line1);
  format-out("%s\n", line2);
  format-out("%s\n\n", line3);
end method;

led-numbers();
