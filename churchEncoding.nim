import definitions
import interpreter

# ======== Church Encoding =================
var zero = Abs("s", Abs("z", Var("z")))
var suc  = Abs("n",
  Abs("s",
    Abs("z",
      App(
        Var("s"),
        App(
          App(Var("n"), Var("s")),
          Var("z")
        )
      )
    )
  )
)

var plus = Abs("m",
  Abs("n",
    Abs("s",
      Abs("z",
        App(
          App(Var("m"), Var("s")),
          App(
            App(Var("n"), Var("s")),
            Var("z")
          )
        )
      )
    )
  )
)
var one   = evaluate(App(suc, zero))
var two   = evaluate(App(suc, one))
var three = evaluate(App(suc, two))
var four  = evaluate(App(App(plus, two), two))
var eight = evaluate(App(App(plus, four), four))

var True  = Abs("then", Abs("else", Var("then")))
var False = Abs("then", Abs("else", Var("else")))
var And   = Abs("p", Abs("q", App(App(Var("p"), Var("q")), Var("p"))))
var If    = Abs("p", Abs("a", Abs("b", App(App(Var("p"), Var("a")), Var("b")))))
var nIs0  = Abs("n", App(App(Var("n"), Abs("x", False)), True))
var Pred  = Abs("n", Abs("f", Abs("x",
  App(
    App(
      App(
        Var("n"),
        Abs("g", Abs("h",
          App(Var("h"), App(Var("g"), Var("f")))
        ))
      ),
      Abs("u", Var("x"))
    ),
    Abs("u", Var("u"))
  )
)))

var g = Abs("r", Abs("n",
  App(
    App(
      App(nIs0, Var("n")),
      zero
    ),
    App(
      App(plus, Var("n")),
      App(Var("r"), App(Pred, Var("n")))
    )
  )
))

# λg.(λx.g (x x)) (λx.g (x x))
var Y = Abs("g",
  App(
    Abs("x", App(Var("g"), App(Var("x"), Var("x")))),
    Abs("x", App(Var("g"), App(Var("x"), Var("x"))))
  )
)

var G = App(Y, g) # Compute sum([0..n])
var U = Abs("x", App(Var("x"), Var("x")))
var OMEGA = App(U, U)

var p0 = App(App(And, True), False)
var p1 = App(Y, Var("fun"))
var p2 = App(Pred, one)
var p3 = App(nIs0, p2)
var p4 = App(G, four)
var p5 = App(Abs("x", Var("y")), OMEGA)

evaluate(p0, true)
evaluate(p1, true, gas=2)
evaluate(p2, true)
evaluate(p3, true)
evaluate(p4, true, gas=500)
evaluate(p5, true, gas=2)

evaluate(zero, true) # (\s.(\z.z))
evaluate(one, true) # (\s.(\z.(s z)))
evaluate(two, true) # (\s.(\z.(s (s z))))
evaluate(three, true) # (\s.(\z.(s (s (s z)))))
evaluate(four, true) # (\s.(\z.(s (s (s (s z))))))
evaluate(eight, true) # (\s.(\z.(s (s (s (s (s (s (s (s z))))))))))
