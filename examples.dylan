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

