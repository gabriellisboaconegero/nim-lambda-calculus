import definitions
import interpreter
import parser

var t0 = Abs("x", Var("x"))
var t1 = Abs("x", App(Var("x"), Var("y")))
var t2 = Abs("x", Abs("y", App(Var("x"), Var("y"))))
var t3 = App(t2, t0)
var t4 = Abs("y", t1)
var t5 = Abs("a", Abs("b", App(Var("a"), App(Var("a"), Var("b")))))
var t6 = App(App(Abs("x", App(Var("x"), Var("x"))), Var("y")), Abs("x", Var("x")))
var t7 = App(Abs("x", App(Var("x"), Var("x"))), Abs("x", App(Var("x"), Var("x"))))
var t8 = App(
  Abs(
    "x",
    App(
      App(Var("x"), Var("1")),
      App(Var("x"), Var("2"))
    )
  ),
  Abs(
    "y",
    Abs(
      "z",
      App(Var("y"), Var("z"))
    )
  )
)
var t9 = App(App(t5, Var("b")), Var("hey"))
var t10 = App(Abs("x", App(Abs("y", Var("y")), Var("x"))), Var("hey"))
var t11 = Abs("x",
  App(
    Abs("y",
      Abs("z",
        App(App(Var("x"), Var("y")), Var("z"))
      )
    ),
    Abs("w",
      Var("x")
    )
  )
)

# (λx. λy. z x (λu. u x)) (λx. w x).
var t12 = App(
  Abs("x",
    Abs("y",
      App(
        App(Var("z"), Var("x")),
        Abs("u",
          App(Var("u"), Var("x"))
        )
      )
    )
  ),
  Abs("x",
    App(Var("w"), Var("x"))
  )
)

var t13 = Abs("x",
  App(
    Abs("y",
      Abs("z",
        App(App(Var("x"), Var("y")), Var("z"))
      )
    ),
    App(
      Var("w"),
      Var("x")
    )
  )
)

var t = t11

evaluate(t0, true) # should be: (\x.x)
evaluate(t1, true) # (\x.(x y))
evaluate(t2, true) # (\x.(\y.(x y)))
evaluate(t3, true) # (\y.y)
evaluate(t4, true) # (\y.(\x.(x y)))
evaluate(t5, true) # (\a.(\b.(a#1 (a#1 b#0))))
evaluate(t6, true) # ((y y) (\x.x))
evaluate(t7, true, gas=4) # runs forever
evaluate(t8, true) # (1 (\z.(2 z)))
evaluate(t9, true) # (b#0 (b#0 hey#0))
evaluate(t10, true) # hey#0
evaluate(t11, true) # (\x.(\z.((x#1 (\w.x#2)) z#0)))
evaluate(t12, true) # (\y.((z#1 (\x.(w#2 x#0))) (\u.(u#0 (\x.(w#3 x#0))))))
evaluate(t13, true) # (\x.(\z.((x#1 (w#2 x#1)) z#0)))
echo alphaEquivalence(lamb"\x.x", lamb"\y.y")
echo alphaEquivalence(lamb"\x.(\y.\z.l z) (\u.x)", lamb"\r.(\y.\p.k p) (\c.c)")

