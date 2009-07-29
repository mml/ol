Summary
=======

This x86-targeting compiler for a Ruby-like language is under construction, but
partially works.

Files
-----

    Makefile            Instructions for make(1).
    README              This file
    compiler.rb         Parse tree -> AST pass, and AST -> assembly.
    driver.c            C runtime support
    lang.rb             Parse tree support classes
    ol.treetop          Grammar definition
    test-driver.rb      List of tests and support functions for running them

To see stuff happen, run

    make test

then have a look at `test-driver.rb`.

Language
--------

The language is a simplified subset of Ruby.  A complete [PEG][1] will follow, but
from Ruby we will take the following notions initially.

- All values are objects.
- All objects belong to classes (distinct from io and JavaScript).
- The only named unit of computation is a method (no unattached
  functions/subroutines).
- The same identifier rules, including that classes/constants start with a
  capital letter.
- @ and $ as scoping sigils
- "Primitive" types: nil, true, false, Fixnums
- the following forms
  - class...end (with '< Foo' superclass specification)
  - def...end
  - if...else...elsif...end and variants
  - while...end
  - assignment
  - method calls
  - syntactic sugar to convert infix operators to method calls: + - * / << >> ==
- syntax restrictions from Ruby
  - ()s on method defs and calls are not, for now, optional

Implementation
--------------

The implementation plan is a variation on http://is.gd/1osYC

- Write a rough grammar in [treetop][3]
- Start by writing enough of a compiler to emit fixnums
  - Then add other immediate values (true, false, nil)
  - Then unary and binary primitives (!, +, *, ==, etc.)
  - Then single assignment of variables
  - Then conditionals
  - Then heap-allocation
    - This implies strings, arrays and certain primitives thereupon
  - Then method definition and invocation
    - This will include proper scoping for method-local variables
  - Then complex literals (e.g., [1,2,3])
  - Then multiple assignment (boxing and unboxing).
  - Then proper tail calls
  - Then lambda {}.
    - As a syntactic form, at this point, rather than as generalized support for
      blocks.
  - Then a rewriting pass that:
    - Gives all variables unique names
    - Translates looping constructs into other forms.
  - Then classes and inheritance.
  - Then runtime error checking and safer prims
  - Register allocation and other "don't be dumb" optimizations.
  - Garbage collector
    - Probably stop-and-copy

Long-term goals
---------------
- Reliable and correct
- High usability.  In particular, top-notch error mesages.
- Produces fast, space-efficient code

Anticipated Improvements
------------------------
### Compiler
- Optimizations
### Language
- lambda and blocks
- Strings
- Arrays
- all of Ruby (use [Markus Liedl's full Ruby grammar][2]?)
### Runtime
- A better garbage collector

[1]: http://en.wikipedia.org/wiki/Parsing_expression_grammar
[2]: http://rubyforge.org/projects/ruby-tp-dw-gram/
[3]: http://treetop.rubyforge.org/
