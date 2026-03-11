import std/strformat

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

