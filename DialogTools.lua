local view = import "LrView"
local bind = view.bind
local function_context = import 'LrFunctionContext'
local tasks = import "LrTasks"
local dialogs = import "LrDialogs"
local path_utils = import "LrPathUtils"
local file_utils = import "LrFileUtils"
----------------------------------------------------------------------------------------------------

-- Functions used on buttons to edit group-list
----------------------------------------------------------------------------------------------------
function build_grouplist(property_table)
  local groups = {}
  local rslt = {}
  local i, group
  
  table.insert (groups, { title = LOC "$$$/Ipernity/Dialog/groups/no_group=no group selected", value = nil } )
  
  rslt = iperAPI_request ("group.getList", { 
    user_id = property_table.user_id,
    auth_token = property_table.token, 
  }) 
  if rslt.api.status == "ok" then
    if rslt.groups.total > 0 then
      for i, group in ipairs (rslt.groups.group) do
        table.insert(groups, { title = group.title, value = group.group_id } )
      end
    end
    property_table.group_list = groups
  else
    dialogs.message (rslt.api.code .. " " .. rslt.api.message)
  end
end

function add_group(property_table)
  local t = {}
  if property_table.selected_group ~= nil then
    t = property_table.upload_group_ids
    t [property_table.selected_group] = 1
    property_table.upload_group_ids = t
  end
end

function remove_group(property_table)
  local t = {}
  if property_table.selected_group ~= nil then
    t = property_table.upload_group_ids
    t [property_table.selected_group] = nil
    property_table.upload_group_ids = t
  end
end

function clear_group_list(property_table)
  property_table.upload_group_ids = {}
end

-- Functions used on buttons to edit album-list
----------------------------------------------------------------------------------------------------
function build_albumlist(property_table)
  local albums = {}
  rslt = {}
  local i, album
  
  table.insert (albums, { title = LOC "$$$/Ipernity/Dialog/albums/no_album=no album selected", value = nil } )
  
  rslt = iperAPI_request ("album.getList", { 
    user_id = property_table.user_id,
    auth_token = property_table.token,
  }) 
  if rslt.api.status == "ok" then
    if rslt.albums.total ~= "0" then   -- this is a string, dont ask why
      for i, album in ipairs (rslt.albums.album) do
        table.insert(albums, { title = album.title, value = album.album_id } )
      end
    end
    property_table.album_list = albums
  else
    dialogs.message (rslt.api.code .. " " .. rslt.api.message)
  end

end

function add_album(property_table)
  local t
  if property_table.selected_album ~= nil then
    t = property_table.upload_album_ids
    t [property_table.selected_album] = 1
    property_table.upload_album_ids = t
  end
end

function remove_album(property_table)
  local t
  if property_table.selected_album ~= nil then
    t = property_table.upload_album_ids
    t [property_table.selected_album] = nil
    property_table.upload_album_ids = t
  end
end

function clear_album_list(property_table)
  property_table.upload_album_ids = {}
end

----------------------------------------------------------------------------------------------------
-- functions to keep property_table in sync, set info-values etc.
----------------------------------------------------------------------------------------------------
function update_ipernity_account(property_table)
  property_table.quota_info = ""
  property_table.quota_left = 0
  property_table.LR_canExport = false
  property_table.LR_cantExportBecause = LOC "$$$/Ipernity/Dialog/NotAuthorized=You haven't authorized this plugin to upload to ipernity yet."     
  
  if (property_table.token == nil) and (property_table.ipernity_id == "n.n.") then
    property_table.ButtonLabel = LOC "$$$/Ipernity/Dialog/Step1=Step 1: authorize"
  end
  
  if (property_table.token ~= nil) and (property_table.ipernity_id == "n.n.") then
    property_table.ButtonLabel = LOC "$$$/Ipernity/Dialog/Step2=Step 2: get token"
  end
  
  if (property_table.token ~= nil) and (property_table.ipernity_id ~= "n.n.") then
    property_table.ButtonLabel = LOC "$$$/Ipernity/Dialog/logout=logout"
    
    property_table.LR_canExport = false
    property_table.LR_cantExportBecause = nil
    property_table.quota_info = "."
    
    function_context.postAsyncTaskWithContext( 'check quota',
    function( context )

      build_albumlist(property_table)
      property_table.quota_info = ".."
      build_grouplist(property_table)              
      property_table.quota_info = "..."
      
      local rslt = iperAPI_request ('account.getQuota', { auth_token = property_table.token })
      if rslt.api.status == "ok" then
        property_table.LR_canExport = true
        property_table.quota_left = rslt.quota.upload.left.bytes 
        property_table.quota_info = LOC ("$$$/Ipernity/Dialog/quota_info=There is ^1 % of your monthly upload quota left.",
          rslt.quota.upload.left.percent)            
      end
      
      if property_table.quota_left == 0 then
        property_table.LR_canExport = false
        property_table.LR_cantExportBecause = LOC "$$$/Ipernity/Dialog/out_of_quota=You have already used your monthly upload-quota."
      end        
    end )      
  end
end
  
function update_privacy(property_table)
  property_table.privacy_synopsis = LOC "$$$/Ipernity/Dialog/Privacy/Private=private"
  
  if property_table.public == 1 then
    property_table.is_private = false
    property_table.family = 0
    property_table.friends = 0
    property_table.privacy_synopsis = LOC "$$$/Ipernity/Dialog/Privacy/Public=public"
  else
    property_table.is_private = true
    if property_table.family == 1 then
      property_table.privacy_synopsis = LOC "$$$/Ipernity/Dialog/Privacy/Family=Family"
    end
    if property_table.friends == 1 then
      property_table.privacy_synopsis = LOC "$$$/Ipernity/Dialog/Privacy/Friends=Friends"
    end
    if (property_table.family == 1) and (property_table.friends == 1) then
      property_table.privacy_synopsis = LOC "$$$/Ipernity/Dialog/Privacy/FamilyFriends=Family & Friends"
    end   
  end

  local i = property_table.license
  if i == 0 then
    property_table.license_info = LOC "$$$/Ipernity/Dialog/License/0=Copyright"
  elseif i == 1 then
    property_table.license_info = LOC "$$$/Ipernity/Dialog/License/1=Attribution (CC by)"
  elseif i == 3 then
    property_table.license_info = LOC "$$$/Ipernity/Dialog/License/3=Attribution+Non Commercial (CC by-nc)"
  elseif i == 5 then
    property_table.license_info = LOC "$$$/Ipernity/Dialog/License/5=Attribution+Non Deriv (CC by-nd)"
  elseif i == 7 then
    property_table.license_info = LOC "$$$/Ipernity/Dialog/License/7=Attribution+Non Commercial+Non Deriv (CC by-nc-nd)"
  elseif i == 9 then
    property_table.license_info = LOC "$$$/Ipernity/Dialog/License/9=Attribution+Share Alike (CC by-sa)"
  elseif i == 11 then
    property_table.license_info = LOC "$$$/Ipernity/Dialog/License/11=Attribution+Non Commercial+Share Alike (CC by-nc-sa)"
  elseif i == 255 then
    property_table.license_info = LOC "$$$/Ipernity/Dialog/License/255=Copyleft"
  else
    property_table.license_info = ""
  end
  
  if property_table.license_info ~= "" then
    property_table.privacy_synopsis = property_table.privacy_synopsis .. ", " .. property_table.license_info
  end
end
  
----------------------------------------------------------------------------------------------------

function build_keyword_list(property_table)

  local tmpdir = path_utils.child (_PLUGIN.path,"tmp") 
  local htmlfilename = path_utils.child(tmpdir,"list.html")  
  
  file_utils.delete (htmlfilename)
  
  local htmlfile = io.open (htmlfilename,"w+")
  
  htmlfile:write ('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">')
  htmlfile:write ('<html>')
  htmlfile:write ('<head>')
  htmlfile:write ('  <title>'
    .. LOC ("$$$/Ipernity/Dialog/list/header=Possible keywords for ^1",property_table.ipernity_id)
    .. '</title>')
  htmlfile:write ('  <script type="text/javascript" src="../lib/table.js"></script>')
  htmlfile:write ('  <link rel="stylesheet" type="text/css" href="../lib/table.css" media="all">')
  htmlfile:write ('  <link rel="stylesheet" type="text/css" href="../lib/css.css" media="all">')
  htmlfile:write ('</head>')
  htmlfile:write ('<body>')
  
  htmlfile:write ('<h1>' 
    .. LOC ("$$$/Ipernity/Dialog/list/header=Possible keywords for ^1",property_table.ipernity_id)
    .. '</h1>')
    
  htmlfile:write (
    LOC "$$$/Ipernity/Dialog/list/hint=You can filter by type and title. Click on the column-header to sort, use regular expressions to filter the title."
    .. '<p>')
 
  htmlfile:write ('<table id="t1" class="example table-autosort table-autofilter table-stripeclass:alternate">')
  htmlfile:write ('<thead>')
  htmlfile:write ('<tr align="left" valign="top">')
  htmlfile:write ('  <th class="table-sortable:default">' .. LOC "$$$/Ipernity/Dialog/keyword=keyword" .. '</th>')
  htmlfile:write ('  <th class="table-filterable">' .. LOC "$$$/Ipernity/Dialog/type=type" .. '</th>')
  htmlfile:write ('  <th class="filterable table-sortable:default">' ..
    LOC "$$$/Ipernity/Dialog/title=title" .. 
    '<br><input name="filter" size="8" onkeyup="Table.filter(this,this)"></th>')
  htmlfile:write ('</tr>')
  htmlfile:write ('</thead>')
  htmlfile:write ('<tbody>')

  for i, group in ipairs(property_table.group_list) do    
    if group.value ~= nil then
      local rslt = iperAPI_request ("group.get", { 
        group_id = group.value,
        auth_token = property_table.token, 
      })
      
      htmlfile:write ('<tr valign="top">')
      htmlfile:write ('<td><b>' .. property_table.group_filter .. group.value .. '</b>')
      htmlfile:write ('<td>' .. LOC "$$$/Ipernity/Dialog/group=group")
      htmlfile:write ('<td>')
      htmlfile:write ('<img src="' .. rslt.group.icon .. '" vspace="5" hspace="5" align="left">')
      htmlfile:write ('<a href="' .. rslt.group.link .. '">' .. group.title .. '</a><p>')
      htmlfile:write (rslt.group.description)
      htmlfile:write ('</tr>')
    end
  end
  
  for i, album in ipairs(property_table.album_list) do
    if album.value ~= nil then
      local rslt = iperAPI_request ("album.get", {
        album_id = album.value,
        auth_token = property_table.token,
      })
      
      htmlfile:write ('<tr valign="top">')
      htmlfile:write ("<td><b>" .. property_table.album_filter .. album.value .. '</b>')
      htmlfile:write ("<td>" .. LOC "$$$/Ipernity/Dialog/album=album")     
      htmlfile:write ("<td>")
      htmlfile:write ('<img src="' .. rslt.album.cover.url .. '" vspace="5" hspace="5" align="left">')
      htmlfile:write ('<a href="' .. rslt.album.link .. '">' .. album.title .. '</a><p>')
      htmlfile:write (rslt.album.description)        
      htmlfile:write ("</tr>")
    end
  end
  htmlfile:write ('</tbody>')
  htmlfile:write ("</table>")
  htmlfile:write ("</body>")
  htmlfile:write ("</html>")

  htmlfile:flush () 
  htmlfile:close ()

  return htmlfilename
end
