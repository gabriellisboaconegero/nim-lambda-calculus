import std/strformat
import definitions
import interpreter
import parser

# ======== Church Encoding =================
var zero = lamb"\s.\z.z"
var suc  = lamb"\n.\s.\z.s (n s) z"

var plus = lamb"\m.\n.\s.\z. (m s) (n s) z"

var one   = evaluate(App(suc, zero))
var two   = evaluate(App(suc, one))
var three = evaluate(App(suc, two))
var four  = evaluate(App(App(plus, two), two))
var eight = evaluate(App(App(plus, four), four))

var True  = lamb"\then.\else.then"
var False = lamb"\then.\else.else"

var And   = lamb"\p.\q.(p q) p"
var nIs0  = lamb(fmt"\n.(n (\x.{False})) {True}")

var Pred  = lamb"\n.\f.\x.n (\g.\h.h (g f)) (\u.x) (\u.u)"
var g = lamb(fmt"\r.\n. ({nIs0} n {zero}) ({plus} n (r ({Pred} n)))")
# var g = (lamb"\r.\n. (nIs0 n zero) (plus n (r (pred n)))")
#           .bindVars({"nIs0": nIs0, "zero": zero, "plus": plus, "pred": Pred})

var Y = lamb"\g.(\x.g (x x)) (\x.g (x x))"

var G = App(Y, g) # Compute sum([0..n])
var U = lamb"\x. x x"
var OMEGA = lamb(fmt"{U} {U}")

var p0 = lamb(fmt"{And} {True} {False}")
var p1 = App(Y, Var("fun"))
var p2 = App(Pred, one)
var p3 = App(nIs0, p2)
var p4 = App(G, four)
var p5 = lamb(fmt"(\x.y) {OMEGA}")

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
