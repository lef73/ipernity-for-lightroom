local dialogs = import "LrDialogs"
local tasks = import "LrTasks"
local function_context = import 'LrFunctionContext'
local app = import 'LrApplication'
local progress_scope = import 'LrProgressScope'

require ("IpernityUploadTask")

UpdateToIpernity = {}

function UpdateToIpernity.process_photos ()
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
        title = nphotos > 1 and LOC ( "$$$/Ipernity/UpdateIpernity/Progress=Updating data on Ipernity for ^1 photos", nphotos)
          or LOC "$$$/Ipernity/UpdateIpernity/Progress1=Updating data at Ipernity for one photo",
        caption = LOC "$$$/Ipernity/Update/Reading=Sending Metadata to Ipernity...",
        functionContext = context,
      }
  
  
      for i,photo in ipairs(photos) do  
        update_ipernity_metadata (catalog,photo.uuid)
        update_lightroom_metadata (catalog,photo.uuid)
        
        progress:setPortionComplete (i,nphotos)
        
        if progress:isCanceled() then return end
      end
    end
  )
end  

UpdateToIpernity.process_photos()