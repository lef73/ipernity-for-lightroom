----------------------------------------------------------------------------------------------------
-- functions to decode JSON-Strings - from JSON4Lua
function decode_scanWhitespace(s,startPos)
  local whitespace=" \n\r\t"
  local stringLen = string.len(s)
  while ( string.find(whitespace, string.sub(s,startPos,startPos), 1, true)  and startPos <= stringLen) do
    startPos = startPos + 1
  end
  return startPos
end

function decode_scanObject(s,startPos)
  local object = {}
  local stringLen = string.len(s)
  local key, value
  startPos = startPos + 1
  repeat
    startPos = decode_scanWhitespace(s,startPos)
    local curChar = string.sub(s,startPos,startPos)
    if (curChar=='}') then
      return object,startPos+1
    end
    if (curChar==',') then
      startPos = decode_scanWhitespace(s,startPos+1)
    end
    -- Scan the key
    key, startPos = json_decode(s,startPos)
    startPos = decode_scanWhitespace(s,startPos)
    startPos = decode_scanWhitespace(s,startPos+1)
    value, startPos = json_decode(s,startPos)
    object[key]=value
  until false	-- infinite loop while key-value pairs are found
end

function decode_scanString(s,startPos)
  local startChar = string.sub(s,startPos,startPos)
  local escaped = false
  local endPos = startPos + 1
  local bEnded = false
  local stringLen = string.len(s)
  repeat
    local curChar = string.sub(s,endPos,endPos)
    if not escaped then	
      if curChar==[[\]] then
        escaped = true
      else
        bEnded = curChar==startChar
      end
    else
      -- If we're escaped, we accept the current character come what may
      escaped = false
    end
    endPos = endPos + 1
  until bEnded
  local stringValue = 'return ' .. string.sub(s, startPos, endPos-1)
  local stringEval = loadstring(stringValue)
  return stringEval(), endPos  
end

function decode_scanConstant(s, startPos)
  local consts = { ["true"] = true, ["false"] = false, ["null"] = nil }
  local constNames = {"true","false","null"}

  for i,k in ipairs(constNames) do
    --print ("[" .. string.sub(s,startPos, startPos + string.len(k) -1) .."]", k)
    if string.sub(s,startPos, startPos + string.len(k) -1 )==k then
      return consts[k], startPos + string.len(k)
    end
  end
end

function decode_scanArray(s,startPos)
  local array = {}	-- The return value
  local stringLen = string.len(s)
  startPos = startPos + 1
  -- Infinite loop for array elements
  repeat
    startPos = decode_scanWhitespace(s,startPos)
    local curChar = string.sub(s,startPos,startPos)
    if (curChar==']') then
      return array, startPos+1
    end
    if (curChar==',') then
      startPos = decode_scanWhitespace(s,startPos+1)
    end
    object, startPos = json_decode(s,startPos)
    table.insert(array,object)
  until false
end

function decode_scanNumber(s,startPos)
  local endPos = startPos+1
  local stringLen = string.len(s)
  local acceptableChars = "+-0123456789.e"
  while (string.find(acceptableChars, string.sub(s,endPos,endPos), 1, true)
	and endPos<=stringLen
	) do
    endPos = endPos + 1
  end
  local stringValue = 'return ' .. string.sub(s,startPos, endPos-1)
  local stringEval = loadstring(stringValue)
  return stringEval(), endPos
end

function decode_scanComment(s, startPos)
  local endPos = string.find(s,'*/',startPos+2)
  return endPos+2  
end

function json_decode(s, startPos)
  startPos = startPos and startPos or 1
  startPos = decode_scanWhitespace(s,startPos)

  local curChar = string.sub(s,startPos,startPos)
  -- Object
  if curChar=='{' then
    return decode_scanObject(s,startPos)
  end
  -- Array
  if curChar=='[' then
    return decode_scanArray(s,startPos)
  end
  -- Number
  if string.find("+-0123456789.e", curChar, 1, true) then
    return decode_scanNumber(s,startPos)
  end
  -- String
  if curChar==[["]] or curChar==[[']] then
    return decode_scanString(s,startPos)
  end
  if string.sub(s,startPos,startPos+1)=='/*' then
    return json_decode(s, decode_scanComment(s,startPos))
  end
  -- Otherwise, it must be a constant
  return decode_scanConstant(s,startPos)
end

function encodeString(s)
  s = string.gsub(s,'\\','\\\\')
  s = string.gsub(s,'"','\\"')
  s = string.gsub(s,"'","\\'")
  s = string.gsub(s,'\n','\\n')
  s = string.gsub(s,'\t','\\t')
  return s 
end

function isArray(t)
  -- Next we count all the elements, ensuring that any non-indexed elements are not-encodable 
  -- (with the possible exception of 'n')
  local maxIndex = 0
  for k,v in pairs(t) do
    if (type(k)=='number' and math.floor(k)==k and 1<=k) then	-- k,v is an indexed pair
      if (not isEncodable(v)) then return false end	-- All array elements must be encodable
      maxIndex = math.max(maxIndex,k)
    else
      if (k=='n') then
        if v ~= table.getn(t) then return false end  -- False if n does not hold the number of elements
      else -- Else of (k=='n')
        if isEncodable(v) then return false end
      end  -- End of (k~='n')
    end -- End of k,v not an indexed pair
  end  -- End of loop across all pairs
  return true, maxIndex
end

function isEncodable(o)
  local t = type(o)
  return (t=='string' or t=='boolean' or t=='number' or t=='nil' or t=='table') or (t=='function' and o==null) 
end

function json_encode (v)
  -- Handle nil values
  if v==nil then
    return "null"
  end
  
  local vtype = type(v)  

  -- Handle strings
  if vtype=='string' then    
    return '"' .. encodeString(v) .. '"'	    -- Need to handle encoding in string
  end
  
  -- Handle booleans
  if vtype=='number' or vtype=='boolean' then
    return tostring(v)
  end
  
  -- Handle tables
  if vtype=='table' then
    local rval = {}
    -- Consider arrays separately
    local bArray, maxCount = isArray(v)
    if bArray then
      for i = 1,maxCount do
        table.insert(rval, json_encode(v[i]))
      end
    else	-- An object, not an array
      for i,j in pairs(v) do
        if isEncodable(i) and isEncodable(j) then
          table.insert(rval, '"' .. encodeString(i) .. '":' .. json_encode(j))
        end
      end
    end
    if bArray then
      return '[' .. table.concat(rval,',') ..']'
    else
      return '{' .. table.concat(rval,',') .. '}'
    end
  end
  
  -- Handle null values
  if vtype=='function' and v==null then
    return 'null'
  end
end

