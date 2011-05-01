require ("APIKit")

local fileutils = import "LrFileUtils"
local pathutils = import "LrPathUtils"
local dialogs = import "LrDialogs"
local tasks = import "LrTasks"
local date = import "LrDate"
local shell = import "LrShell"

local function_context = import 'LrFunctionContext'

IpernityUploadTask = {}

----------------------------------------------------------------------------------------------------
function get_ipernity_id (catalog,uuid)
  local ipernity_id = nil

  catalog:withCatalogDo( function ()
    local photo = catalog:findPhotoByUuid (uuid)
    ipernity_id = photo:getPropertyForPlugin (_PLUGIN,"ipernity_id");
    if ipernity_id == nil then
      ipernity_id = photo:getPropertyForPlugin (_PLUGIN,"ipernity_id_set")
    end
  end)
  
  return ipernity_id
end

----------------------------------------------------------------------------------------------------
function wait_for_ticket (ticket_no, progress_scope, property_table)
  -- wait for ipernity to complete processing uploaded photos
  local delay = 1
  local total_delay = 0
  local rslt = {}
  while delay > 0 do
    rslt = iperAPI_request ("upload.checkTickets", {
      auth_token = property_table.token,
      tickets = ticket_no,
    })
    if rslt.api.status == "ok" then
      delay = rslt.tickets.eta
    else          
      dialogs.message (rslt.api.code .. " " .. rslt.api.message)
      delay = -1
    end
    tasks.sleep (delay)  
    total_delay = total_delay + delay
    progress_scope:setCaption (LOC("$$$/Ipernity/Upload/Progress/wait=waiting since ^1 sec. for ipernity to process photo", total_delay))
    if progress_scope:isCanceled() then 
      return false 
    end
  end
  
  return delay == 0
end

----------------------------------------------------------------------------------------------------
function remove_ipernity_link (catalog,uuid)

  catalog:withWriteAccessDo( LOC "$$$/Ipernity/Upload/update_metadata=update of metadata",
  function ()
  
    local photo = catalog:findPhotoByUuid (uuid)   

    if photo ~= nil then 
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_is_uploaded",false)
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_url",nil)
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_id",nil)
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_token",nil)    
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_tags",nil)
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_albums",nil)
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_groups",nil)    
    end
  end )
end

----------------------------------------------------------------------------------------------------
function update_lightroom_metadata (catalog,uuid)

  local ipernity_id_set = nil
  local ipernity_id = nil
  local token = nil

  catalog:withCatalogDo( function ()
    local photo = catalog:findPhotoByUuid (uuid)
    ipernity_id = photo:getPropertyForPlugin (_PLUGIN,"ipernity_id");
    ipernity_id_set = photo:getPropertyForPlugin (_PLUGIN,"ipernity_id_set");
    token = photo:getPropertyForPlugin (_PLUGIN,"ipernity_token");
  end)
  
  if ipernity_id_set ~= nil then
    ipernity_id = ipernity_id_set
  end
  
  local rslt = iperAPI_request ("doc.get", { 
    auth_token = token,
    doc_id = ipernity_id,
    extra = "tags",
  })
  
  catalog:withWriteAccessDo( LOC "$$$/Ipernity/Upload/update_metadata=update of metadata",
  function ()      
    local photo = catalog:findPhotoByUuid (uuid)
    if rslt.api.status == "ok" then 
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_id_set",nil)
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_id",ipernity_id)

      photo:setPropertyForPlugin (_PLUGIN,"ipernity_is_uploaded",true)
      
      photo:setRawMetadata ("title",rslt.doc.title);
      local description = string.gsub (rslt.doc.description,"<hr />.*","");
      photo:setRawMetadata ("caption",description);
      
      if rslt.doc.license == "255" then
        copyright = LOC "$$$/Ipernity/Dialog/License/255=Copyleft"
      elseif rslt.doc.license == "11" then
        copyright = LOC "$$$/Ipernity/Dialog/License/11=Attribution+Non Commercial+Share Alike (CC by-nc-sa)"
      elseif rslt.doc.license == "9" then
        copyright = LOC "$$$/Ipernity/Dialog/License/9=Attribution+Share Alike (CC by-sa)"
      elseif rslt.doc.license == "7" then
        copyright = LOC "$$$/Ipernity/Dialog/License/7=Attribution+Non Commercial+Non Deriv (CC by-nc-nd)"
      elseif rslt.doc.license == "5" then
        copyright = LOC "$$$/Ipernity/Dialog/License/5=Attribution+Non Deriv (CC by-nd)"
      elseif rslt.doc.license == "3" then
        copyright = LOC "$$$/Ipernity/Dialog/License/3=Attribution+Non Commercial (CC by-nc)"
      elseif rslt.doc.license == "1" then
        copyright = LOC "$$$/Ipernity/Dialog/License/1=Attribution (CC by)"
      else
        copyright = LOC "$$$/Ipernity/Dialog/License/0=Copyright"
      end
      photo:setRawMetadata ("copyright", copyright);
      
      local privacy = "0";
      if (rslt.doc.visibility.isfamily == 1) then privacy = "1" end      
      if (rslt.doc.visibility.isfriends == 1) then privacy = "2" end
      if (rslt.doc.visibility.isfamily == 1) and (rslt.doc.visibility.isfriends == 1) then privacy = "3" end
      if (rslt.doc.visibility.ispublic == 1) then privacy = "4" end
      photo:setPropertyForPlugin (_PLUGIN,"privacy",privacy);
          
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_tags",nil)
      
      if rslt.doc.tags.total > 0 then
        local tags = ""
        local i, tag
        for i,tag in ipairs(rslt.doc.tags.tag) do
          tags = add_tag (tags, tag.title, ",")
        end      
        if tags ~= "" then photo:setPropertyForPlugin (_PLUGIN,"ipernity_tags",tags); end
      end
      
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_url",rslt.doc.link)

      photo:setPropertyForPlugin (_PLUGIN,"ipernity_user",rslt.doc.owner.username)

    end
  end)

  if rslt.api.status == "ok" then
    rslt = iperAPI_request ("doc.getContainers", {
      auth_token = token,
      doc_id = ipernity_id,
    })
  else
    -- Document not found
    if rslt.api.status == "error" and rslt.api.code == 1 then
      remove_ipernity_link (catalog,uuid)
      
      if ipernity_id_set ~= nil then
        dialogs.message (LOC ("$$$/Ipernity/Dialog/Link/1=Unable to link to document ^1",ipernity_id_set),
          LOC "$$$/Ipernity/Dialog/Link/2=The document could not be found or you were not allowed to access it (anonymously).")
      end
    end
    return
  end
 
  catalog:withWriteAccessDo( LOC "$$$/Ipernity/Upload/update_metadata=update of metadata",
  function ()      
    local photo = catalog:findPhotoByUuid (uuid)
    if rslt.api.status == "ok" then
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_groups",nil)
      if rslt.groups ~= nil then
        local groups = ""
        local i, group
        for i, group in ipairs(rslt.groups.group) do
          -- groups = add_tag (groups, group.title .. " (" .. group.group_id .. ")",",")
          groups = add_tag (groups, group.title, ",")
        end
        if groups ~= "" then photo:setPropertyForPlugin (_PLUGIN,"ipernity_groups",groups); end
      end
      
      photo:setPropertyForPlugin (_PLUGIN,"ipernity_albums",nil)
      if rslt.albums ~= nil then
        local albums = ""
        local i, album
        for i, album in ipairs(rslt.albums.album) do
          -- albums = add_tag (albums, album.title .. " (" .. album.album_id .. ")",",")
          albums = add_tag (albums, album.title, ",")
        end
        if albums ~= "" then photo:setPropertyForPlugin (_PLUGIN,"ipernity_albums",albums); end
      end
    end
  end)

end

----------------------------------------------------------------------------------------------------
function strip_metadata (file)
  local exiftool = ''
  local cmd = ''
  
  if WIN_ENV then
    exiftool = '"' .. _PLUGIN.path .. '\\bin\\exiftool.exe"'
  else
    exiftool = '"' .. _PLUGIN.path .. '/bin/exiftool"'
  end
  
  cmd = exiftool .. ' -all= "' .. file .. '"'
  if WIN_ENV then cmd = '"' .. cmd .. '"' end
  rslt = tasks.execute (cmd)
  
  cmd = exiftool .. ' -overwrite_original -tagsfromfile "' .. file .. '_original" -make '
    .. '-model -exposuretime -aperturevalue -flash -iso -lens -focallength -orientation '
    .. '-datetimeoriginal -ICC_Profile "' .. file .. '"'
  if WIN_ENV then cmd = '"' .. cmd .. '"' end
  rslt = tasks.execute (cmd)
    
  fileutils.delete (file .. "_original")
end

----------------------------------------------------------------------------------------------------
function get_metadata (photo,photo_metadata,property_table)

  photo_metadata.tags = ""
  photo_metadata.groups = {}
  photo_metadata.albums = {}
  photo_metadata.iper_is_public = 0
  photo_metadata.iper_is_friends = 0
  photo_metadata.iper_is_family = 0
  photo_metadata.photo_title = ""
  photo_metadata.photo_description = ""
  photo_metadata.iper_license = ""
  photo_metadata.skip_upload = false

  photo.catalog:withCatalogDo( function()
    photo_metadata.photo_title = photo:getFormattedMetadata 'title'
    if not photo_metadata.photo_title or #photo_metadata.photo_title == 0 then
      photo_metadata.photo_title = photo:getFormattedMetadata 'fileName' --pathutils.leafName( pathOrMessage )
    end
    
    if property_table.auto_tag_equipment then
      photo_metadata.tags = add_tag (photo_metadata.tags,photo:getFormattedMetadata "cameraModel",",")
      photo_metadata.tags = add_tag (photo_metadata.tags,photo:getFormattedMetadata "lens",",")
    end
    
    if property_table.lightroom_tags then
      photo_metadata.tags = add_tag (photo_metadata.tags,photo:getFormattedMetadata "keywordTagsForExport",",")
    end       
    
    exported_tags = split(photo:getFormattedMetadata "keywordTagsForExport" .. "," ,",")
    local j, tag
    for j,tag in ipairs(exported_tags) do
      -- checking for tags
      if property_table.lightroom_tags_filter and (string.starts(tag,property_table.tags_filter)) 
      then
        photo_metadata.tags = add_tag (photo_metadata.tags,string.sub(tag,string.len(property_table.tags_filter)+1),",")
      end
      -- checking for groups
      if property_table.lightroom_group_filter and (string.starts(tag,property_table.group_filter)) 
      then
        photo_metadata.groups[#photo_metadata.groups+1] = string.sub(tag,string.len(property_table.group_filter)+1)
      end           
      -- checking gor albums
      if property_table.lightroom_album_filter and (string.starts(tag,property_table.album_filter)) 
      then
        photo_metadata.albums[#photo_metadata.albums+1] = string.sub(tag,string.len(property_table.album_filter)+1)
      end           
    end
    
    if property_table.auto_tag_date then
      photo_metadata.tags = add_tag (photo_metadata.tags,date.timeToUserFormat(photo:getRawMetadata "dateTimeOriginal","%Y"),",")
    end
    
    photo_metadata.tags = add_tag (photo_metadata.tags,property_table.tags,",")
    
    photo_metadata.photo_description = photo:getFormattedMetadata 'caption'
   
    if property_table.auto_desc_settings then
      local settings_desc = ""
      settings_desc = add_tag (settings_desc,photo:getFormattedMetadata "exposure",", ")
      settings_desc = add_tag (settings_desc,photo:getFormattedMetadata "focalLength",", ")
      settings_desc = add_tag (settings_desc,photo:getFormattedMetadata "isoSpeedRating",", ")
      photo_metadata.photo_description = photo_metadata.photo_description .. "<hr />" .. settings_desc
    end
           
    local privacy = photo:getPropertyForPlugin (_PLUGIN,"privacy");
    if privacy == "-1" then
      photo_metadata.skip_upload = true
    elseif privacy == "0" then
      photo_metadata.iper_is_public = 0;
      photo_metadata.iper_is_friends = 0;
      photo_metadata.iper_is_family = 0;
    elseif privacy == "1" then
      photo_metadata.iper_is_public = 0;
      photo_metadata.iper_is_friends = 0;
      photo_metadata.iper_is_family = 1;
    elseif privacy == "2" then
      photo_metadata.iper_is_public = 0;
      photo_metadata.iper_is_friends = 1;
      photo_metadata.iper_is_family = 0;
    elseif privacy == "3" then
      photo_metadata.iper_is_public = 0;
      photo_metadata.iper_is_friends = 1;
      photo_metadata.iper_is_family = 1;
    elseif privacy == "4" then
      photo_metadata.iper_is_public = 1;
      photo_metadata.iper_is_friends = 0;
      photo_metadata.iper_is_family = 0;
    else
      photo_metadata.iper_is_public = property_table.public;
      photo_metadata.iper_is_friends= property_table.friends;
      photo_metadata.iper_is_family = property_table.family;
    end
    
    local copyright = photo:getFormattedMetadata "copyright"       
    if copyright == LOC "$$$/Ipernity/Dialog/License/0=Copyright" then
      photo_metadata.iper_license = 0
    elseif copyright == LOC "$$$/Ipernity/Dialog/License/1=Attribution (CC by)" then
      photo_metadata.iper_license = 1
    elseif copyright == LOC "$$$/Ipernity/Dialog/License/3=Attribution+Non Commercial (CC by-nc)" then
      photo_metadata.iper_license = 3
    elseif copyright == LOC "$$$/Ipernity/Dialog/License/5=Attribution+Non Deriv (CC by-nd)" then
      photo_metadata.iper_license = 5
    elseif copyright == LOC "$$$/Ipernity/Dialog/License/7=Attribution+Non Commercial+Non Deriv (CC by-nc-nd)" then
      photo_metadata.iper_license = 7
    elseif copyright == LOC "$$$/Ipernity/Dialog/License/9=Attribution+Share Alike (CC by-sa)" then
      photo_metadata.iper_license = 9
    elseif copyright == LOC "$$$/Ipernity/Dialog/License/11=Attribution+Non Commercial+Share Alike (CC by-nc-sa)" then
      photo_metadata.iper_license = 11
    elseif copyright == LOC "$$$/Ipernity/Dialog/License/255=Copyleft" then
      photo_metadata.iper_license = 255
    else
      photo_metadata.iper_license = property_table.license;
    end
  
  end )
end

----------------------------------------------------------------------------------------------------
function create_album (first_uploaded_id,property_table)
  -- create new album for this upload
  if (property_table.upload_album ~= "") and (property_table.upload_album ~= nil) then
    local rslt = iperAPI_request ("album.create" , {
      auth_token = property_table.token,
      title = property_table.upload_album,
      cover_id = first_uploaded_id,
    })
    if rslt.api.status == "ok" then
      property_table.upload_album_ids [rslt.album.album_id] = rslt.album.album_id
    else
      dialogs.message (rslt.api.code .. " " .. rslt.api.message)
    end
  end
end

----------------------------------------------------------------------------------------------------
function add_albums (ipernity_id,token,album_list)
  local key, value

  for key, value in pairs (album_list) do
    local rslt = iperAPI_request ("album.docs.add", {
      auth_token = token,
      album_id = value,
      doc_id = ipernity_id,
    })
  end
end

----------------------------------------------------------------------------------------------------
function add_groups (ipernity_id,token,group_list)
  local key, value

  for key, value in pairs (group_list) do
    local rslt = iperAPI_request ("group.docs.add", {
      auth_token = token,
      group_id = value,
      doc_id = ipernity_id,
    })
  end
end

----------------------------------------------------------------------------------------------------
function IpernityUploadTask.process_rendered_photos ( function_context, export_context )

  local processed_photos = {}
  local first_uploaded_id = 0
  
  local tagged_albums = {}
  local tagged_groups = {}

  rslt = {}

  local export_session = export_context.exportSession
  local property_table = export_context.propertyTable
  
  local nPhotos = export_session:countRenditions()
  local progress_scope = export_context:configureProgress{
    title = nPhotos > 1 and LOC ( "$$$/Ipernity/Upload/Progress=Uploading ^1 photos to ipernity", nPhotos )
      or LOC "$$$/Ipernity/Upload/Progress1=Uploading one photo to ipernity",
  }
  
  local i, rendition  
  for i, rendition in export_context:renditions() do 
    local photo = rendition.photo
    local pathOrMessage = ""
    local success = true
    local ipernity_id = get_ipernity_id (export_session.catalog,photo.uuid)
    if ipernity_id == nil then
      -- Wait until Lightroom has finished rendering this photo. 
      progress_scope:setCaption (LOC("$$$/Ipernity/Upload/Progress/Rendering=preparing photo for upload...")) 
      success, pathOrMessage = rendition:waitForRender() 
      if success then strip_metadata (pathOrMessage) end
    end

    if progress_scope:isCanceled() then break end

    -- Do something with the rendered photo. 
    if success then 
      -- process metadata
      local photo_metadata = {}

      get_metadata (photo,photo_metadata,property_table)
      
      if photo_metadata.skip_upload then
        progress_scope:setCaption (LOC("$$$/Ipernity/Upload/Progress/skipped='^1' skipped for upload", photo_metadata.photo_title))
      else
        local ticket = ""
        
        if ipernity_id == nil then
          progress_scope:setCaption (LOC("$$$/Ipernity/Upload/Progress/Uploading=uploading '^1' to ipernity", photo_metadata.photo_title))
          -- upload photo to ipernity
          
          rslt = iperAPI_request ("upload.file", { 
            auth_token = property_table.token,
            title = photo_metadata.photo_title,
            description = photo_metadata.photo_description,
            is_public = photo_metadata.iper_is_public,
            is_family = photo_metadata.iper_is_family,
            is_friend = photo_metadata.iper_is_friends,
            file = pathOrMessage,
            license = photo_metadata.iper_license,
            keywords = photo_metadata.tags,
          })     
          fileutils.delete( pathOrMessage )     
          
          if rslt.api.status == "ok" then
            ipernity_id = rslt.ticket
            if first_uploaded_id == 0 then first_uploaded_id = ipernity_id end
            ticket = tostring(rslt.ticket)
          else
           rendition:uploadFailed (rslt.api.code .. " " .. rslt.api.message)
           return
          end
        else
          
          
          rslt = iperAPI_request ("doc.set", { 
            auth_token = property_table.token,
            title = photo_metadata.photo_title,
            description = photo_metadata.photo_description,
            doc_id = ipernity_id,
          })
          
          rslt = iperAPI_request ("doc.setPerms", { 
            auth_token = property_table.token,
            is_public = photo_metadata.iper_is_public,
            is_family = photo_metadata.iper_is_family,
            is_friend = photo_metadata.iper_is_friends,
            doc_id = ipernity_id,
          })
          
          rslt = iperAPI_request ("doc.setLicense", { 
            auth_token = property_table.token,
            doc_id = ipernity_id,
            license = photo_metadata.iper_license,
          })
          
          rslt = iperAPI_request ("doc.tags.add", { 
            auth_token = property_table.token,
            doc_id = ipernity_id,            
            keywords = photo_metadata.tags,
          })     

          ticket = ipernity_id
        end
        
        if ticket ~= "" then
          processed_photos [photo.uuid] = ipernity_id
          photo.catalog:withWriteAccessDo( LOC "$$$/Ipernity/Upload/update_metadata=update of metadata",
          function()
            photo:setPropertyForPlugin (_PLUGIN,"ipernity_id",ticket);
            photo:setPropertyForPlugin (_PLUGIN,"ipernity_token",property_table.token);
          end )  

          tagged_albums[ipernity_id] = photo_metadata.albums
          
          if (property_table.public_album ~= nil) and (photo_metadata.iper_is_public == 1) then 
            table.insert(tagged_albums[ipernity_id], property_table.public_album)
          end
          if (property_table.friends_album ~= nil) and (photo_metadata.iper_is_friends == 1) then 
            table.insert(tagged_albums[ipernity_id], property_table.friends_album) 
          end
          if (property_table.family_album ~= nil) and (photo_metadata.iper_is_family == 1) then 
            table.insert(tagged_albums[ipernity_id], property_table.family_album) 
          end
          if (property_table.private_album ~= nil) and (photo_metadata.iper_is_public == 0)
            and (photo_metadata.iper_is_friends == 0) and (photo_metadata.iper_is_family == 0)
          then 
            table.insert(tagged_albums[ipernity_id], property_table.private_album) 
          end        
          
          tagged_groups[ipernity_id] = photo_metadata.groups
        end
      end
    end
  end 
  
  create_album (first_uploaded_id,property_table)
  
  local i = 0  
  local uuid, upload_id
  for uuid, upload_id in pairs(processed_photos) do 
    progress_scope:setPortionComplete (i,nPhotos)
       
    if wait_for_ticket (upload_id, progress_scope, property_table) then
    
      progress_scope:setCaption (nPhotos > 1 and LOC ( "$$$/Ipernity/Upload/Progress/Album=adding ^1 photos to albums and groups", nPhotos )
        or LOC "$$$/Ipernity/Upload/Progress/Album1=adding one photo to albums and groups")

      local key, value
      -- addings general albums
      add_albums (upload_id,property_table.token,property_table.upload_album_ids)      
      -- adding tagged albums
      add_albums (upload_id,property_table.token,tagged_albums[upload_id])

      -- adding general groups
      add_groups (upload_id,property_table.token,property_table.upload_group_ids)
      -- adding tagged groups
      add_groups (upload_id,property_table.token,tagged_groups[upload_id])
      
      update_lightroom_metadata (export_session.catalog ,uuid)

    end
    i = i + 1
  end
end