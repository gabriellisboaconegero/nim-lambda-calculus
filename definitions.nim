import std/strformat
import std/tables

type
  TermKind* = enum
    VariableKind,
    AbstractionKind,
    ApplicationKind
  Term* = ref object
    case kind*: TermKind
      of VariableKind:
        variable*: string
        deBrujinId*: int = -1
      of AbstractionKind:
        boundVar*: string
        body*: Term
      of ApplicationKind:
        lhs*: Term
        rhs*: Term

proc Abs*(boundVar: string, body: Term): Term = 
  return Term(kind: AbstractionKind, boundVar: boundVar, body: body)

proc Var*(variable: string): Term = 
  return Term(kind: VariableKind, variable: variable)

proc App*(lhs: Term, rhs: Term): Term =
  return Term(kind: ApplicationKind, lhs: lhs, rhs: rhs)

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

proc copyTerm*(t: Term): Term =
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

# To use wth fmt, so its like bindVars
# Example:
#   a = lamb"\x.x"
#   b = lamb(fmt"\y.y {a}")
proc `$`*(t: Term): string = 
  return "(" & t.toStr() & ")"

proc bindVars(t: Term, vars: Table[string, Term]): Term
proc bindVars*(t: Term, vars: openArray[(string, Term)] = @[]): Term =
  return t.bindVars(vars.toTable())

proc bindVars(t: Term, vars: Table[string, Term]): Term =
  case t.kind
    of VariableKind:
      if vars.hasKey(t.variable):
        return vars[t.variable]
      return t
    of AbstractionKind:
      if vars.hasKey(t.boundVar):
        return t
      return Abs(t.boundVar, t.body.bindVars(vars))
    of ApplicationKind:
      return App(t.lhs.bindVars(vars), t.rhs.bindVars(vars))
