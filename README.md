# Pure-Lambda-Calculus-in-Perl
### Pure Lambda Calculs in Perl
An Implementation of Pure Lambda Calculus based upon the book, `An Introduction to Functional Programming through Lambda Calculus` by Greg Michaelson (https://books.google.co.kr/books/about/An_Introduction_to_Functional_Programmin.html?id=g)

### Features
  - three kinds of expressions (also called terms) are supported:
    - x (variables)
    - x.e (abstractions)
    - e<sub>1</sub> e<sub>2</sub> (application)
  - substitution occurs at run-time instead of statically  
  - function application by juxtaposition w/o parentheses  
  - parentheses used for grouping only  
  - function definitions in curried form  
  - more descriptive error messages by using exception handling  

### For example,
```
(x.x x.x)   x.x
(x.x s.(s s))   s.(s s)
(s.(s s) x.x)   x.x
((f.g.(f g) x.x) s.(s s))   s.(s s)
def identity = x.x
def self_apply = s.(s s)
def apply = f.g.(f g)
def identity2 = x.((apply identity) x)
(identity2 identity)   identity
(apply f)   g.(f g)
def self_apply2 = s.((apply s) s)
(self_apply2 identity)   identity
def select_first = f.s.f
((select_first identity) apply)   identity
def select_second = f.s.s
((select_second identity) apply)   apply
(select_first identity)   select_second
def make_pair = f.s.g.((g f) s)
((make_pair identity) apply)   g.((g identity) apply)
(((make_pair identity) apply) select_first)   identity
(((make_pair identity) apply) select_second)   apply
(f.(f f.f) s.(s s))   f.f
(f.(f f.f g.(g x.x f) g.f.(f g)) s.(s s))   x.x
```
