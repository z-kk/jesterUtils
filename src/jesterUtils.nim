import
  json, tables, strutils

proc parseNode(params: Table[string, string], keyword: string): JsonNode =
  result = %*{}
  for key, val in params:
    if key.len < keyword.len or key[0..<keyword.len] != keyword:
      continue
    var s = keyword.len
    var l = key.find(']', s)
    if l == key.len - 1:
      result[key[s+1..^2]] = %*val
    elif key[l+1] == '[' and key.find(']', l+1) > 0:
      let k = key[0..l]
      if result.hasKey(k[k.rfind('[')+1..^2]):
        continue
      result[k[k.rfind('[')+1..^2]] = params.parseNode(k)

# Jesterのrequest.paramsをJsonに変換
proc parseJson*(params: Table[string, string]): JsonNode =
  result = %*{}
  for key, val in params:
    var s = key.find('[')
    if s < 0:
      result[key] = %*val
      continue
    var l = key.find(']', s)
    if s < l:  # [より右に]がある
      let k = key[0..<s]
      if result.hasKey(k):
        continue
      result[k] = params.parseNode(k)
