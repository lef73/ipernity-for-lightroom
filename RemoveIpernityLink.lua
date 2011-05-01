local dialogs = import "LrDialogs"
local tasks = import "LrTasks"
local function_context = import 'LrFunctionContext'
local app = import 'LrApplication'
local progress_scope = import 'LrProgressScope'

require ("IpernityUploadTask")

RemoveIpernityLink = {}

function RemoveIpernityLink.process_photos ()
  local catalog = app.activeCatalog()
  local photos = {}
  local photo = nil
  local i = 0
  
  catalog:withReadAccessDo (function()
    photos = catalog.targetPhotos
  end)
  
  if photos == {} then return end
  local nphotos = #photos
  
  if dialogs.confirm (
    nphotos > 1 and LOC("$$$/Ipernity/Unlink/Question=Do you really want to unlink ^1 photos?", nphotos)
    or LOC "$$$/Ipernity/Unlink/Question1=Do you really want to unlink this photo?",
    LOC "$$$/Ipernity/Remove/Hint=The Ipernity-Metadata will be removed in Lightroom. No data will be deleted on the ipernity website.") ~= "ok" 
  then return end

  function_context.postAsyncTaskWithContext( 'unlink ipernity',
    function(context)
  
      local progress = progress_scope {
        title = nphotos > 1 and LOC ( "$$$/Ipernity/Unlink/Progress=Unlinking ^1 photos from Ipernity", nphotos)
          or LOC "$$$/Ipernity/Unlink/Progress1=Unlinking one photo from Ipernity",
        caption = LOC "$$$/Ipernity/Unlink/Remove=Removing Ipernity-Metadata...",
        functionContext = context,
      }
      
      for i,photo in ipairs(photos) do  
        remove_ipernity_link (catalog,photo.uuid)
        progress_scope:setPortionComplete(i, nphotos)
          
        if progress:isCanceled() then return end
      end
    end
  )
end

RemoveIpernityLink.process_photos()