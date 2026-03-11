import definitions
import std/re
import std/strformat

# GRAMMAR
# E       ::= ABS | APP | VAR | (E)
# ABS     ::= \var. E
# APP     ::= E APP | E E
# VAR     ::= var
#
# ABS ::= \var. ABS | APP
# APP ::= F APP | F
# F ::= VAR | (E)

const
  ws: set[char] = {' ', '\t'}
  alphaChar: set[char] = {'a'..'z', 'A'..'Z'}

type
  TokenKind = enum
    VariableToken,
    SlashToken,
    DotToken,
    OpenToken,
    CloseToken,
    EOFToken,
    ERRORToken
  Token = tuple
    kind: TokenKind
    data: string
  Tokenizer = object
    stream: string
    ic: int = 0
  ParserError* = object of Exception

proc toToken(tKind: TokenKind): Token =
  if tKind == ERRORToken:
    return (kind: tKind, data: "ERRO")
  return (kind: tKind, data: "")

proc identifier(t: var Tokenizer): Token =
  let mLen = matchLen(t.stream, re"[a-zA-Z_][a-zA-Z_0-9]*", t.ic)
  if mLen > 0:
    result = (kind: VariableToken, data: t.stream[t.ic..t.ic + mLen - 1])
    t.ic += mLen
  else:
    result = ERRORToken.toToken()

proc untoken(t: var Tokenizer, tk: Token) =
  if tk.kind == VariableToken:
    t.ic -= tk.data.len()
  else:
    t.ic -= 1

  t.ic = max(t.ic, 0)

proc nextToken(t: var Tokenizer): Token =
  while t.ic < t.stream.len():
    case t.stream[t.ic]
      of alphaChar:
        let tk = t.identifier()
        return tk
      of '\\':
        t.ic += 1
        return SlashToken.toToken()
      of '.':
        t.ic += 1
        return DotToken.toToken()
      of '(':
        t.ic += 1
        return OpenToken.toToken()
      of ')':
        t.ic += 1
        return CloseToken.toToken()
      of ws:
        t.ic += 1
      else:
        return ERRORToken.toToken()

  return EOFToken.toToken()

proc match(tokenizer: var Tokenizer, tkKind: TokenKind): string {.discardable.} =
  let ic = tokenizer.ic
  let tk = tokenizer.nextToken()

  if tk.kind != tkKind:
    raise newException(ParserError, fmt("[ERRO]: {tkKind} excpected, found {tk.kind} {tk.data} in {ic}"))
  
  return tk.data

# ABS ::= \var. ABS | APP
# APP ::= F APP | F
# F ::= VAR | (E)
proc parseABS(tokenizer: var Tokenizer): Term

proc parseF(tokenizer: var Tokenizer): Term =
  # echo fmt("F: enter {tokenizer.ic}")
  var tk = tokenizer.nextToken()
  # echo fmt("F: next {tokenizer.ic} {tk.kind} {tk.data}")

  case tk.kind:
    of VariableToken:
      return Var(tk.data)
    of OpenToken:
      var ntk = parseABS(tokenizer)
      tokenizer.match(CloseToken)
      # echo fmt("F: exit {tokenizer.ic}")
      return ntk
    else:
      raise newException(ParserError, fmt("[ERRO]: found {tk.kind} {tk.data} in {tokenizer.ic}"))

proc parseAPP(tokenizer: var Tokenizer): Term =
  # echo fmt("APP: enter {tokenizer.ic}")
  var lhs = parseF(tokenizer)
  var tk = tokenizer.nextToken()
  # echo fmt("APP: next {tokenizer.ic} {tk.kind} {tk.data}")

  case tk.kind:
    of CloseToken:
      tokenizer.untoken(tk)
      return lhs
    of EOFToken:
      return lhs
    else:
      tokenizer.untoken(tk)
      var rhs = parseAPP(tokenizer)
      # echo fmt("APP: exit {tokenizer.ic}")
      return App(lhs, rhs)
  
proc parseABS(tokenizer: var Tokenizer): Term =
  # echo fmt("ABS: enter {tokenizer.ic}")
  var tk = tokenizer.nextToken()
  # echo fmt("ABS: next {tokenizer.ic} {tk.kind} {tk.data}")
  var boundVarName: string

  case tk.kind:
    of SlashToken:
      boundVarName = tokenizer.match(VariableToken)
      tokenizer.match(DotToken)
      let body = parseABS(tokenizer)
      # echo fmt("ABS: exit {tokenizer.ic}")
      return Abs(boundVarName, body)
    else:
      tokenizer.untoken(tk)
      var r = parseAPP(tokenizer)
      # echo fmt("ABS: exit {tokenizer.ic}")
      return r
  

proc parse*(input: string): Term =
  var tokenizer = Tokenizer(stream: input)

  return parseABS(tokenizer)

# Using as lamb"str" does not require scaping
# the \, but using as lamb("str") require
proc lamb*(input: string): Term = 
  return parse(input)
