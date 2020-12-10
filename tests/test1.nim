import unittest

import jesterUtils, tables, json
test "parseJson":
  var params: Table[string, string]
  params = {"hoge[fuga][foo][boo]": "true", "152005[eres]": "true", "hoge[hoge]": "true", "hoge[fuga][boo]": "false", "152005[ares]": "true"}.toTable
  check params.parseJson["hoge"]["fuga"]["foo"]["boo"].getStr == "true"

test "parseMultiPartData":
  let
    data = readFile("tests/multipartdata")
    datas = data.parseMultiPartData

  check datas[0].name & datas[1].contType & datas[2].fileName & datas[3].data == "aimage/bmpc.jpghogedata"
