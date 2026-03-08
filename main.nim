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

proc termToStr(t: Term, fmtDeBrujin: bool = false): string = 
  case t.kind
    of VariableKind:
      if fmtDeBrujin:
        return fmt("#{t.deBrujinId}")
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

proc fixDeBrujinRepresentation(t: var Term) =
  case t.kind
    of VariableKind:
      return
    of AbstractionKind:
      bindVariables(t.body, t.boundVar)
      fixDeBrujinRepresentation(t.body)
    of ApplicationKind:
      fixDeBrujinRepresentation(t.lhs)
      fixDeBrujinRepresentation(t.rhs)

proc substituteBoundVariable(body: Term, val: Term, dbijLevel: int = 0): Term = 
  # echo fmt("sub: {body.kind} {dbijLevel}")
  # echo fmt("sub: {termToStr(body)}")
  case body.kind:
    of VariableKind:
      if (dbijLevel == body.deBrujinId):
        # echo fmt("sub: found bound var {body.variable}")
        return val
      return body
    of AbstractionKind:
      return Abs(body.boundVar, substituteBoundVariable(body.body, val, dbijLevel+1))
    of ApplicationKind:
      let tmp =  App(
        substituteBoundVariable(body.lhs, val, dbijLevel),
        substituteBoundVariable(body.rhs, val, dbijLevel),
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
      let lhs = step(t.lhs)

      if (lhs != t.lhs):
        # echo fmt("step: lhs changed")
        return App(lhs, t.rhs)
      
      if (lhs.kind == AbstractionKind):
        # echo fmt("step: sub")
        # echo termToStr(t.rhs)
        return substituteBoundVariable(t.lhs.body, t.rhs)

      let rhs = step(t.rhs)
      if (rhs != t.rhs):
        # echo fmt("step: rhs changed")
        return App(lhs, rhs)

      return t

proc evaluate(t: var Term, show: bool = false): Term = 
  fixDeBrujinRepresentation(t)

  if show:
    echo "==================="
    echo termToStr(t)
    echo termToStr(t, true)

  var nt = step(t)
  while (t != nt):
    # if show:
    #   echo termToStr(nt)
    #   echo termToStr(nt, true)
    
    t = nt
    nt = step(t)

  if show:
    echo termToStr(t)
    echo termToStr(t, true)
    echo "==================="
  return t



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
var t9 = App(t5, Var("b"))

discard evaluate(t0, true) # should be: (\x.x)
discard evaluate(t1, true) # (\x.(x y))
discard evaluate(t2, true) # (\x.(\y.(x y)))
discard evaluate(t3, true) # (\y.y)
discard evaluate(t4, true) # (\y.(\x.(x y)))
discard evaluate(t5, true) # (\a.(\b.(a (a b)))) / (\a.(\b.(#1 (#1 #0))))
discard evaluate(t6, true) # ((y y) (\x.x))
# discard evaluate(t7, true) # runs forever
discard evaluate(t8, true) # (1 (\z.(2 z)))
discard evaluate(t9, true) # (\b.(b (b b))) / (\b.(#-1 (#-1 #0)))

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

discard evaluate(zero, true) # (\s.(\z.z))
discard evaluate(one, true) # (\s.(\z.(s z)))
discard evaluate(two, true) # (\s.(\z.(s (s z))))
discard evaluate(three, true) # (\s.(\z.(s (s (s z)))))
discard evaluate(four, true) # (\s.(\z.(s (s (s (s z))))))
discard evaluate(eight, true) # (\s.(\z.(s (s (s (s (s (s (s (s z))))))))))
