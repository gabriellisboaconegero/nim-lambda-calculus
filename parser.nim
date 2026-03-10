import definitions
import std/re

# GRAMMAR
# E       ::= ABS | APP | VAR | (E)
# ABS     ::= \var. E
# APP     ::= E APP | E E
# VAR     ::= var
#

const
  ws: set[char] = {' ', '\t'}
  lowerCaseChar: set[char] = {'a'..'z'}

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

proc nextToken(t: var Tokenizer): Token =
  while t.ic < t.stream.len():
    case t.stream[t.ic]
      of lowerCaseChar:
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

