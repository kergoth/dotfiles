-- mbox parser
-- based on code by Diego Nahab

mbox = {}

local function headers (s)
  local header = {}
  s = "\n" .. s .. "$$$:\n"
  local i, j = 1, 1
  while true do
    j = string.find (s, "\n%S-:", i + 1)
    if not j then
      break
    end
    local _, _, name, val = string.find (string.sub (s, i + 1, j - 1),
                                         "(%S-):(.*)")
    val = string.gsub (val or "", "\r\n", "\n")
    val = string.gsub (val, "\n%s*", " ")
    name = string.lower (name)
    if header[name] then
      header[name] = header[name] .. ", " ..  val
    else
      header[name] = val
    end
    i, j = j, i
  end
  header["$$$"] = nil
  return header
end

local function message (s)
  s = string.gsub (s, "^.-\n", "")
  local _, s, body
  _, _, s, body = string.find(s, "^(.-\n)\n(.*)")
  return {header = headers (s or ""), body = body or ""}
end

function mbox.parse (s)
  local mbox = {}
  s = "\n" .. s .. "\nFrom "
  local i, j = 1, 1
  while true do
    j = string.find (s, "\nFrom ", i + 1)
    if not j then
      break
    end
    table.insert (mbox, message (string.sub (s, i + 1, j - 1)))
    i, j = j, i
  end
  return mbox
end
