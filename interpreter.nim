import std/strformat
import std/macros
import definitions

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

proc toStr*(t: Term, fmtDeBrujin: bool = false): string = 
  case t.kind
    of VariableKind:
      if fmtDeBrujin:
        return fmt("{t.variable}#{t.deBrujinId}")
      else:
        return t.variable
    of AbstractionKind:
      let bodyStr = toStr(t.body, fmtDeBrujin)
      return fmt("(\\{t.boundVar}.{bodyStr})")
    of ApplicationKind:
      let strLhs = toStr(t.lhs, fmtDeBrujin)
      let strRhs = toStr(t.rhs, fmtDeBrujin)
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
  # echo fmt("fix: {toStr(t, true)}")
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
  # echo fmt("shift: {toStr(t, true)} {dbjiLevel} {k}")
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
  # echo fmt("sub: {toStr(body, true)}")
  case body.kind:
    of VariableKind:
      if (dbjiLevel == body.deBrujinId):
        # echo fmt("sub: found bound var {body.variable}")
        var v = copyTerm(val)
        shift(v, -1, dbjiLevel)
        # echo fmt("sub: {toStr(v, true)}")

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
      
      # echo fmt("sub: {toStr(tmp)}")
      return tmp

proc reductionStep*(t: Term): Term

proc normalOrderRedux(t: Term): Term {.inline.} =
  if (t.lhs.kind == AbstractionKind):
    # echo fmt("step: sub")
    # echo toStr(t.rhs)
    return substituteBoundVariable(t.lhs.body, t.rhs)

  let lhs = reductionStep(t.lhs)
  if (lhs != t.lhs):
    # echo fmt("step: lhs changed")
    return App(lhs, t.rhs)


  let rhs = reductionStep(t.rhs)
  if (rhs != t.rhs):
    # echo fmt("step: rhs changed")
    return App(lhs, rhs)

  return t

proc applicativeOrderRedux(t: Term): Term {.inline.} =
  let lhs = reductionStep(t.lhs)
  if (lhs != t.lhs):
    # echo fmt("step: lhs changed")
    return App(lhs, t.rhs)

  let rhs = reductionStep(t.rhs)
  if (rhs != t.rhs):
    # echo fmt("step: rhs changed")
    return App(lhs, rhs)

  if (lhs.kind == AbstractionKind):
    # echo fmt("step: sub")
    # echo toStr(t.rhs)
    return substituteBoundVariable(lhs.body, t.rhs)

  return t


# Normal Order: leftmost outermost
proc reductionStep*(t: Term): Term =
  # echo fmt("step: {t.kind} {toStr(t)}")
  case t.kind:
    of VariableKind:
      return t
    of AbstractionKind:
      let body = reductionStep(t.body)
      if (body != t.body):
        return Abs(t.boundVar, body)

      return t
    of ApplicationKind:
      return normalOrderRedux(t)
      # return applicativeOrderRedux(t)


proc evaluate*(
    term: Term,
    show: bool = false,
    showSteps: bool = false,
    gas: int = 100
  ): Term {.discardable.} = 
  var t = term
  fixDeBrujinRepresentation(t)

  if show:
    echo "==================="
    echo toStr(t, true)

  var steps = 1
  var nt = reductionStep(t)
  while (t != nt and steps < gas):
    if (show and showSteps):
      echo fmt("step: {toStr(nt, true)}")
    
    t = nt
    nt = reductionStep(t)

    steps += 1

  if t != nt and show:
    echo "out of gas"

  if show:
    echo toStr(nt, true)
    echo "==================="
  return nt

