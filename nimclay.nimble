when defined(nimsuggest):
  import system/nimscript

version       = "0.2.0"
author        = "Nimaoth"
description   = "Nim wrapper for clay"
license       = "MIT"
srcDir        = "src"

requires "nim >= 2.0.8"
# requires "https://github.com/Nimaoth/nimgen >= 0.5.4"

# const cmd = when defined(Windows): "cmd /c " else: ""

# task nimgen, "Nimgen":
#   if gorgeEx(cmd & "nimgen").exitCode != 0:
#     withDir(".."):
#       exec "nimble install nimgen -y"

#   exec cmd & "nimgen nimclay.cfg"

# before install:
#   nimgenTask()
