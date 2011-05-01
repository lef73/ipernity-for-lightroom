----------------------------------------------------------------------------------------------------
function add_tag (s,tag,separator)
  local rslt = s
  
  if (tag ~= nil) and (tag ~= "") then    
    if (s ~= "") and (s ~= nil) then rslt = s .. separator end
    rslt = rslt .. tag
  end
  
  return rslt
end

----------------------------------------------------------------------------------------------------
function split (s,t)
  local l = {n=0}
  local f = function (s)
    l.n = l.n + 1
    l[l.n] = s
  end
  local p = "%s*(.-)%s*"..t.."%s*"
  s = string.gsub(s,"^%s+","")
  s = string.gsub(s,"%s+$","")
  s = string.gsub(s,p,f)
  if s ~= string.gsub(s,"(%s%s*)$","") then
    l.n = l.n + 1
    l[l.n] = string.gsub(s,"(%s%s*)$","")
  end
  return l
end

----------------------------------------------------------------------------------------------------
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

----------------------------------------------------------------------------------------------------
function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end
