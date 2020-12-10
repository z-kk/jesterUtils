import
  json, tables, strutils

type
  HttpDataInfo* = object
    name*, fileName*, contType*, data*: string

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

proc parseJson*(params: Table[string, string]): JsonNode =
  ## Jesterのrequest.paramsをJsonに変換
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

proc parseMultiPartData*(body: string): seq[HttpDataInfo] =
  ## multipart/form-dataで送信されたデータを解析
  let lineList = body.split("\r\n")
  if lineList.len < 3:
    return

  let separator = lineList[0]
  var isData = false
  for line in lineList:
    if not isData or line.startsWith(separator) or result[^1].contType == "":
      echo line
    else:
      echo "--data--"

    if line == separator:
      result.add(HttpDataInfo())
      isData = false
    elif line.startsWith(separator):
      return
    elif line == "":
      isData = true
    elif not isData:
      var i = line.find("; name=\"")
      if i > -1:
        # nameを設定する
        let str = line[i + 8 .. ^1]
        i = str.find('"')

        while i > 0 and str[i - 1] == '\\':  # エスケープ文字を考慮
          i.inc(str[i + 1 .. ^1].find('"'))

        if i == str.len - 1 or str[i + 1] == ';':
          result[^1].name = str[0 ..< i]
        else:
          raiseAssert("name取得失敗")

      i = line.find("; filename=\"")
      if i > -1:
        # fileNameを設定する
        let str = line[i + 12 .. ^1]
        i = str.find('"')

        while i > 0 and str[i - 1] == '\\':  # エスケープ文字を考慮
          i.inc(str[i + 1 .. ^1].find('"'))

        if i == str.len - 1 or str[i + 1] == ';':
          result[^1].fileName = str[0 ..< i]
        else:
          raiseAssert("filename取得失敗")

      i = line.find("Content-Type: ")
      if i > -1:
        # contTypeを設定する
        let str = line[i + 14 .. ^1]
        i = str.find(';')
        result[^1].contType =
          if i < 0:
            str
          else:
            str[0 ..< i]
    else:
      if result[^1].data != "":
        result[^1].data &= "\r\n" & line
      else:
        result[^1].data = line
