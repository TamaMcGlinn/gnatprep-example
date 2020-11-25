# Goal

Have a robust, readable way of specifying preprocessing inside Ada program text,
supporting multiple compilers and requiring minimal recompilation. Need
solutions for both file-based inclusion and #ifdef-style within a single file.

# Gprbuild

Gprbuild allows us to check environment variables and choose source directories
to include. These will contain the body of a package or subprogram. This
fulfills the file-based inclusion mechanism for the GNAT compiler.

Every Ada compiler system is expected to have some way to conditionally
add certain source directories; but we haven't tried any other compilers here.

# [Gnatprep](https://docs.adacore.com/gnat_ugn-docs/html/gnat_ugn/gnat_ugn/the_gnat_compilation_model.html#preprocessing-with-gnatprep)

Lines beginning with '#' are preprocessor directives, which tell gnatprep how
to determine whether or not the corresponding Ada program text should be
compiled. Gnatprep can be run standalone to preprocess files for other
compilers, but for GNAT it can be run in-process, which simplifies the process.
Gnatprep will modify the source files depending on the values of symbols, just
like the preprocessors built into the specification of many other programming
languages.

# Basic mechanism

We pass environment variable definitions to gprbuild, e.g.:

```
gprbuild -XFoo_feature=no_foo_feature
```

Inside the gpr file, we specify the valid values using an enumeration type:

```
   type Foo_Feature_Type is ("foo_feature", "no_foo_feature");
   Foo_Feature : Foo_Feature_Type := external ("Foo_feature");
```

By reading the values in this way, we force a compiler-failure if the flag is
not present. We also get a compiler failure if the value passed does not exactly
match one of the specified values.

# Conditional program text

There are two ways to use the symbols defined in the gpr project file. Since
both ways use the same way of passing the values in, it is a backward
compatible change to switch from one to the other usage.

## Conditional source directory

We can select source directories based on the values given:

```
   for Source_Dirs use ("src",
                        "src/" & Foo_Feature,
                        "src/" & Bar_Feature);
```

The directories could contain different bodies corresponding to the same
specification file, or could contain entire packages that are available in one
but not the other configuration (for instance, src/no_foo_feature could be an
empty directory). We are also not limited to two-valued switches.

For more advanced examples of this technique, see the [AUnit repository](https://github.com/AdaCore/aunit/blob/master/lib/gnat/aunit_shared.gpr).
AUnit has an extra level of indirection; you choose a runtime profile, which
then determines the values of other variables. This can be combined with the
examples given here, so that certain features can only be selected together.

This technique can be combined with separates in order to have a separate file
defining a single subprogram for each configuration.

## Conditionally active program text

In the gpr project file, we can also choose to pass the environment variable on
as a gnatprep parameter:

```
for Switches ("Ada") use ("-gnateDFoo_Feature=" & Foo_Feature);
```

And then, inside the program text, we could do e.g.:

```
   #if Foo_Feature = "foo_feature" then
      Put_Line ("Have Foo feature");
   #else
      Put_Line ("Do not have Foo feature");
   #end if;
```

Again we are not limited to two values for each preprocessor symbol.

## External program text

It is also possible to substitute symbols outside the #-prefixed lines, e.g.

```
Bar : constant := $Bar;
```

Using the same mechanisms shown above, the project file gets the value for Bar
from an environment variable using 'external ("Bar_Value")' and passes this on
to gnatprep with `"-gnateDBar=" & Bar_Value`. For values, it might not make
sense to limit the values to a predefined set. On the other hand, it might be
sensible to assume a default value:

```
Bar := external ("Bar", "0.3");
```

In this case, running `gprbuild` without specifying a value will use the
universal real '0.3' by default. We can also:
  - give a different default value depending on the value of other flags,
  - require a value only if some flag is enabled
  - create a symbol based on specified or default values, e.g. "Total=Bar * Foo"

# Caveat; recompiling

If you first compile with one set of flags, and then compile again with other
flags, gprbuild would normally say that everything is up-to-date and not
recompile. To avoid this wrong behaviour, we specify that the object directory
contains each of the flag values. That way, when we switch flags, we have also
switched to a different object directory and hence things are recompiled. It
also has the advantage that when switching back, packages previously built with
the same flags do not need to be rebuilt.

# Debug statements

As noted in the GNAT userguide in the section on preprocessing, it is not
necessary to use a preprocessor specifically for adding and removing debug
statements, as these can be more conveniently added by the Debug pragma:

```
pragma Debug (Put_Line ("got to the first stage!"));
```

Debug pragmas are enabled using either the -gnata switch that also controls
assertions, or with a separate Debug_Policy pragma. Since this is a
GNAT-specific extension, these statements also won't be printed when using a
different compiler. Since that doesn't affect release builds that
doesn't seem to pose any problem.

# Try it!

This repository contains some conditional program text; try compiling with e.g.:

```
gprbuild -d -p -g -XBar=bar -XFoo=no_foo -XAmount=0.1
```

And run `./obj/bar_no_foo_Amount0.1/main.exe` to verify that Foo was not
included but bar is, and amount is set to 0.1.
