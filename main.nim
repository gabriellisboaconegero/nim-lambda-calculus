import std/strformat

type
  TermKind = enum
    VariableKind,
    AbstractionKind,
    ApplicationKind
  Term = ref object
    case kind: TermKind
    of VariableKind:
      variable: string
      deBrujinId: int = -1 # -1 named. 0> De Brujin representation
    of AbstractionKind:
      boundVar: string
      body: Term
    of ApplicationKind:
      lhs, rhs: Term

proc Abs(boundVar: string, body: Term): Term = 
  return Term(kind: AbstractionKind, boundVar: boundVar, body: body)

proc Var(variable: string): Term = 
  return Term(kind: VariableKind, variable: variable)

proc App(lhs: Term, rhs: Term): Term =
  return Term(kind: ApplicationKind, lhs: lhs, rhs: rhs)

proc copyTerm(t: Term): Term =
  case t.kind:
    of VariableKind:
      let v = Var(t.variable)
      v.deBrujinId = t.deBrujinId
      return v
    of AbstractionKind:
      return Abs(t.boundVar, copyTerm(t.body))
    of ApplicationKind:
      return App(
        copyTerm(t.lhs),
        copyTerm(t.rhs)
      )

proc termToStr(t: Term, fmtDeBrujin: bool = false): string = 
  case t.kind
    of VariableKind:
      if fmtDeBrujin:
        return fmt("{t.variable}#{t.deBrujinId}")
      else:
        return t.variable
    of AbstractionKind:
      let bodyStr = termToStr(t.body, fmtDeBrujin)
      return fmt("(\\{t.boundVar}.{bodyStr})")
    of ApplicationKind:
      let strLhs = termToStr(t.lhs, fmtDeBrujin)
      let strRhs = termToStr(t.rhs, fmtDeBrujin)
      return fmt("({strLhs} {strRhs})")

proc bindVariables(t: var Term, boundVar: string, level: int = 0) =
  case t.kind
    of VariableKind:
      if boundVar == t.variable:
        t.deBrujinId = level
    of AbstractionKind: 
      if boundVar == t.boundVar: return
      bindVariables(t.body, boundVar, level+1)
    of ApplicationKind:
      bindVariables(t.lhs, boundVar, level)
      bindVariables(t.rhs, boundVar, level)

proc fixDeBrujinRepresentation(t: var Term, dbjiLevel: int = 0) =
  # echo fmt("fix: {t.kind}")
  # echo fmt("fix: {termToStr(t, true)}")
  case t.kind
    of VariableKind:
      if t.deBrujinId == -1:
        t.deBrujinId = dbjiLevel
    of AbstractionKind:
      bindVariables(t.body, t.boundVar)
      fixDeBrujinRepresentation(t.body, dbjiLevel+1)
    of ApplicationKind:
      fixDeBrujinRepresentation(t.lhs, dbjiLevel)
      fixDeBrujinRepresentation(t.rhs, dbjiLevel)

proc shift(t: var Term, dbjiLevel: int, k: int) =
  # echo fmt("shift: {termToStr(t, true)} {dbjiLevel} {k}")
  case t.kind:
    of VariableKind:
      if t.deBrujinId > dbjiLevel:
        t.deBrujinId += k
    of AbstractionKind:
      shift(t.body, dbjiLevel+1, k)
    of ApplicationKind:
      shift(t.lhs, dbjiLevel, k)
      shift(t.rhs, dbjiLevel, k)

proc substituteBoundVariable(body: Term, val: Term, dbjiLevel: int = 0): Term = 
  # echo fmt("sub: {body.kind} {dbjiLevel}")
  # echo fmt("sub: {termToStr(body, true)}")
  case body.kind:
    of VariableKind:
      if (dbjiLevel == body.deBrujinId):
        # echo fmt("sub: found bound var {body.variable}")
        var v = copyTerm(val)
        shift(v, -1, dbjiLevel)
        # echo fmt("sub: {termToStr(v, true)}")

        return v
      if (dbjiLevel < body.deBrujinId):
        body.deBrujinId -= 1
      return body
    of AbstractionKind:
      return Abs(body.boundVar, substituteBoundVariable(body.body, val, dbjiLevel+1))
    of ApplicationKind:
      let tmp =  App(
        substituteBoundVariable(body.lhs, val, dbjiLevel),
        substituteBoundVariable(body.rhs, val, dbjiLevel),
      )
      
      # echo fmt("sub: {termToStr(tmp)}")
      return tmp

proc step(t: Term): Term =
  # echo fmt("step: {t.kind} {termToStr(t)}")
  case t.kind:
    of VariableKind:
      return t
    of AbstractionKind:
      let body = step(t.body)
      if (body != t.body):
        return Abs(t.boundVar, body)

      return t
    of ApplicationKind:
      if (t.lhs.kind == AbstractionKind):
        # echo fmt("step: sub")
        # echo termToStr(t.rhs)
        return substituteBoundVariable(t.lhs.body, t.rhs)

      let lhs = step(t.lhs)
      if (lhs != t.lhs):
        # echo fmt("step: lhs changed")
        return App(lhs, t.rhs)
      

      let rhs = step(t.rhs)
      if (rhs != t.rhs):
        # echo fmt("step: rhs changed")
        return App(lhs, rhs)

      return t

proc evaluate(t: var Term, show: bool = false, showSteps: bool = false, gas: int = high(int)): Term = 
  fixDeBrujinRepresentation(t)

  if show:
    echo "==================="
    echo termToStr(t, true)

  var steps = 1
  var nt = step(t)
  while (t != nt and steps < gas):
    if (show and showSteps):
      echo fmt("step: {termToStr(nt, true)}")
    
    t = nt
    nt = step(t)

    steps += 1

  if show:
    echo termToStr(nt, true)
    echo "==================="
  return nt



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

discard evaluate(t0, true) # should be: (\x.x)
discard evaluate(t1, true) # (\x.(x y))
discard evaluate(t2, true) # (\x.(\y.(x y)))
discard evaluate(t3, true) # (\y.y)
discard evaluate(t4, true) # (\y.(\x.(x y)))
discard evaluate(t5, true) # (\a.(\b.(a#1 (a#1 b#0))))
discard evaluate(t6, true) # ((y y) (\x.x))
# discard evaluate(t7, true) # runs forever
discard evaluate(t8, true) # (1 (\z.(2 z)))
discard evaluate(t9, true) # (b#0 (b#0 hey#0))
discard evaluate(t10, true) # hey#0
discard evaluate(t11, true) # (\x.(\z.((x#1 (\w.x#2)) z#0)))
discard evaluate(t12, true) # (\y.((z#1 (\x.(w#2 x#0))) (\u.(u#0 (\x.(w#3 x#0))))))
discard evaluate(t13, true) # (\x.(\z.((x#1 (w#2 x#1)) z#0)))

# ======== Church Numerals =================
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
var one   = App(suc, zero)
var two   = App(suc, one)
var three = App(suc, two)
var four  = App(App(plus, two), two)
var eight  = App(App(plus, four), four)

var True = Abs("then", Abs("else", Var("then")))
var False = Abs("then", Abs("else", Var("else")))
var And = Abs("p", Abs("q", App(App(Var("p"), Var("q")), Var("p"))))

# λg.(λx.g (x x)) (λx.g (x x))
var Y = Abs("g",
  App(
    Abs("x", App(Var("g"), App(Var("x"), Var("x")))),
    Abs("x", App(Var("g"), App(Var("x"), Var("x"))))
  )
)

var p0 = App(App(And, True), False)
var p1 = App(Y, Var("fun"))

discard evaluate(p0, true)
discard evaluate(p1, true, gas=2)


discard evaluate(zero, true) # (\s.(\z.z))
discard evaluate(one, true) # (\s.(\z.(s z)))
discard evaluate(two, true) # (\s.(\z.(s (s z))))
discard evaluate(three, true) # (\s.(\z.(s (s (s z)))))
discard evaluate(four, true) # (\s.(\z.(s (s (s (s z))))))
discard evaluate(eight, true) # (\s.(\z.(s (s (s (s (s (s (s (s z))))))))))
