# Lmabda calculus in Nim
This is a lambda calculus implementation in Nim, inpired by:
* https://youtu.be/KuVUfbWoROw?si=5FdoRlhDFFeg1t78
* https://plfa.github.io/DeBruijn/

The `evaluate`, `step` and `substituteBoundVariable` functions are heavily inspired by
the tsoding methods `eval` and `apply`. But with teh diference that my solver tries to apply
beta-reduction to all branches of the term. Each step only does one beta-reduction on the left most
sub-term.

To solve the problems with bound and free variables, the term is transformed to and mixed
encoding of De Brujin indices (DBIJ ID) and named variables. Bound variables get the DBIJ ID, corresponded
to the corret abstraction level, and free variables receive `-1`.

## How to use
```bash
# nim compile main.nim
nim c main.nim
./main
```
