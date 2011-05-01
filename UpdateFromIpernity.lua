local dialogs = import "LrDialogs"
local tasks = import "LrTasks"
local function_context = import 'LrFunctionContext'
local app = import 'LrApplication'
local progress_scope = import 'LrProgressScope'

require ("IpernityUploadTask")

UpdateFromIpernity = {}

function UpdateFromIpernity.process_photos ()
  local catalog = app.activeCatalog()
  local photos = {}
  local photo = nil
  local i = 0

  catalog:withReadAccessDo (function()
    photos = catalog.targetPhotos
  end)
  
  if photos == {} then return end
  
  local nphotos = #photos

  function_context.postAsyncTaskWithContext( 'update metadata',
    function(context)
  
      local progress = progress_scope {
        title = nphotos > 1 and LOC ( "$$$/Ipernity/Update/Progress=Updating Metadata for ^1 photos", nphotos)
          or LOC "$$$/Ipernity/Update/Progress1=Updating Metadata for one photo",
        caption = LOC "$$$/Ipernity/Update/Reading=Fetching Metadata from Ipernity...",
        functionContext = context,
      }
    
      for i,photo in ipairs(photos) do  
        update_lightroom_metadata (catalog,photo.uuid)
        progress:setPortionComplete (i,nphotos)
        
        if progress:isCanceled() then return end
      end
    end
  )
end  

UpdateFromIpernity.process_photos()