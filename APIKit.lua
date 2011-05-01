---------------------------------------------------------------------------------------------------
-- Basic routines for calling API-methods
----------------------------------------------------------------------------------------------------
require ("APISecrets")
require ("APIJsonTools")
require ("Toolkit")
----------------------------------------------------------------------------------------------------
local md5 = import ('LrMD5')
local http = import ('LrHttp')
local pathutils = import ('LrPathUtils')
local dialogs = import ('LrDialogs')
--local tasks = import ('LrTasks')
--local date = import ('LrDate')

----------------------------------------------------------------------------------------------------
function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str	
end

----------------------------------------------------------------------------------------------------
function iperAPI_signParams (method, params)
  local sig = ''
  local keys = {}
  local key, values
  local i

  for key,values in pairs (params) do
    table.insert(keys,key)
  end
  table.sort(keys)
  
  for i,key in pairs(keys) do
    sig = sig .. key .. params[key]
  end
  
  sig = sig .. method .. APISECRET
  
  return md5.digest (sig)
end

----------------------------------------------------------------------------------------------------
function iperAPI_buildQueryString (params)
  local query = ''
  local key, value
  
  for key,value in pairs (params) do
    if query ~= '' then query = query .. "&" end
    query = query .. key .. "=" .. url_encode(value)
  end
  
  return query
end

----------------------------------------------------------------------------------------------------
function iperAPI_request (method, params)
  local fullfilepath = ''
  local url = ""
  local chunks = {}
  local key, value
  local rslt = ""
  
  if not params then params = {} end

  params ["api_key"] = APIKEY
  if params [ "file" ] then
    fullfilepath = params [ "file" ]
    params [ "file" ] = nil
  end
  params ["api_sig"] = iperAPI_signParams (method,params)
  
  url = APIURL .. "/" .. method .. "/json" 
  
  for key,value in pairs (params) do chunks [#chunks+1] = { name = key, value = value } end 
  if fullfilepath ~= '' then
    chunks [#chunks+1] = { name = 'file', 
      filePath = fullfilepath, fileName = pathutils.leafName(fullfilepath), 
      contentType = 'application/octet-stream'}
  end
  
  rslt = http.postMultipart(url, chunks)
  
  return json_decode(rslt);
end

----------------------------------------------------------------------------------------------------
function iperAPI_request_debug (method, params)
  local fullfilepath = ''
  local url = ""
  local chunks = {}
  local key, value
  local rslt = ""

  if not params then params = {} end
  fullfilepath = ''

  params ["api_key"] = APIKEY
  if params [ "file" ] then
    fullfilepath = params [ "file" ]
    params [ "file" ] = nil
  end
  params ["api_sig"] = iperAPI_signParams (method,params)
  
  url = APIURL .. "/" .. method .. "/json" 
  
  chunks = {}
  for key,value in pairs (params) do chunks [#chunks+1] = { name = key, value = value } end 
  if fullfilepath ~= '' then
    chunks [#chunks+1] = { name = 'file', 
      filePath = fullfilepath, fileName = pathutils.leafName(fullfilepath), 
      contentType = 'application/octet-stream'}
  end
  
  rslt = http.postMultipart(url, chunks)

  dialogs.message (method,rslt)
  
  return json_decode(rslt);
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function iperAPI_authurl ()
  local rslt = {}

  rslt = iperAPI_request ("auth.getFrob")
  
  if rslt.api.status == "ok" then
    params = {}
    params.api_key = APIKEY 
    params.perm_doc = "write"    
    params.frob = rslt.auth.frob
    params.api_sig = iperAPI_signParams ('',params)
    http.openUrlInBrowser(AUTHURL .. "?" .. iperAPI_buildQueryString(params))
    return rslt.auth.frob
  else
    dialogs.message (rslt.api.code .. " " .. rslt.api.message)
  end
end

----------------------------------------------------------------------------------------------------
function iperAPI_getToken (temp_frob)
  local rslt = {}
  
  rslt = iperAPI_request ("auth.getToken",{ frob=temp_frob })
  if rslt.api.status == "ok" then
    return rslt.auth.token
  else
    dialogs.message (rslt.api.code .. " " .. rslt.api.message)
  end
end

----------------------------------------------------------------------------------------------------
function iperAPI_checkToken (property_table)
  rslt = {}
  
  property_table.ipernity_id = "n.n."
  
  rslt = iperAPI_request ("auth.checkToken", { auth_token = property_table.token })   
  
  if rslt.api.status == "ok" then
    property_table.user_id = rslt.auth.user.user_id
    property_table.ipernity_id= rslt.auth.user.username
      .. " (" .. rslt.auth.user.realname .. ")"
  else
    dialogs.message (rslt.api.code .. " " .. rslt.api.message)
  end
end