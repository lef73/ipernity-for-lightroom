-- Dialogs
---------------------------------------------------------------------------------------------------
require ("APIKit")
require ("DialogTools")

Dialog = {}

local LrBinding = import 'LrBinding'
local view = import "LrView"
local dialogs = import "LrDialogs"
local function_context = import 'LrFunctionContext'
local bind = view.bind


----------------------------------------------------------------------------------------------------
function Dialog.start_dialog(property_table)
  property_table.LR_minimizeEmbeddedMetadata = false
  property_table.LR_metadata_keywordOptions = "lightroomHierarchical"
  
  -- reset some properties, which must be set per upload
  property_table.upload_album = ""
  property_table.upload_album_ids = {}
  property_table.upload_album_info = LOC "$$$/Ipernity/Dialog/albums/no_album=no album selected"
  property_table.upload_group_ids = {}
  property_table.upload_group_info = LOC "$$$/Ipernity/Dialog/groups/no_group=no group selected"
  
  ------------------------------------
  property_table:addObserver('token', update_ipernity_account)
  property_table:addObserver('ipernity_id', update_ipernity_account) 
  
  property_table:addObserver('public', update_privacy)
  property_table:addObserver('family', update_privacy)
  property_table:addObserver('friends', update_privacy)
  property_table:addObserver('license', update_privacy)
  
  property_table:addObserver('lightroom_tags', function()
    if property_table.lightroom_tags then property_table.lightroom_tags_filter = false end
  end)
  
  property_table:addObserver('lightroom_tags_filter', function()
    if property_table.lightroom_tags_filter then property_table.lightroom_tags = false end
  end)
  
  update_ipernity_account(property_table)
  update_privacy(property_table)  
end

----------------------------------------------------------------------------------------------------
function Dialog.export_top_sections(f, property_table )
  return {  
    {
      title = LOC "$$$/Ipernity/Dialog/Account=Ipernity Account",
      synopsis = bind 'privacy_synopsis',
  
      f:row {
        f:static_text {
          title = bind 'ipernity_id',
          alignment = 'left',
          fill_horizontal = 1,
          font = "<system/bold>",
        },
    
        f:push_button {
          width = 160,
          title = bind 'ButtonLabel',
          action = function()
            function_context.postAsyncTaskWithContext( 'Call Auth URL',
            function( context )
              if property_table.token == nil then
                property_table.token = iperAPI_authurl ()
              elseif property_table.ipernity_id == "n.n." then
                property_table.token = iperAPI_getToken (property_table.token)
                iperAPI_checkToken (property_table)
              else
                property_table.token = nil
                property_table.ipernity_id = "n.n."
              end              
            end )
          end,
        },
      },
      f:row {
        f:static_text {
          title = bind('quota_info'),
          alignment = 'left', 
          fill_horizontal = 1,
          size = 'mini',
        },
      },

      f:row { 
        f:separator {
          fill_horizontal = 1,
        },
      },

      f:row {
        spacing = f:control_spacing(),
        
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/Privacy/header=Uploaded photos will be visible for"
        },
        
        f:checkbox {
          title = LOC "$$$/Ipernity/Dialog/Privacy/Public=all users",
          value = bind 'public',
          checked_value = 1, unchecked_value = 0,
        },

        f:checkbox {
          title = LOC "$$$/Ipernity/Dialog/Privacy/Family=your Family",
          value = bind 'family',
          enabled = bind 'is_private',
          checked_value = 1, unchecked_value = 0,
        },

        f:checkbox {
          title = LOC "$$$/Ipernity/Dialog/Privacy/Friends=your Friends",
          value = bind 'friends',
          enabled = bind 'is_private',
          checked_value = 1, unchecked_value = 0,
        },

      },

      f:row {
        spacing = f:control_spacing(),
        
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/License/header=License used for publishing: "
        },
	
        f:popup_menu {
          title = LOC "$$$/Ipernity/Dialog/License/License=License",
          value = bind 'license',
          items = {
            { title = LOC "$$$/Ipernity/Dialog/License/0=Copyright", value = 0 },
            { title = LOC "$$$/Ipernity/Dialog/License/1=Attribution (CC by)", value = 1 },
            { title = LOC "$$$/Ipernity/Dialog/License/3=Attribution+Non Commercial (CC by-nc)", value = 3 },
            { title = LOC "$$$/Ipernity/Dialog/License/5=Attribution+Non Deriv (CC by-nd)", value = 5 },
            { title = LOC "$$$/Ipernity/Dialog/License/7=Attribution+Non Commercial+Non Deriv (CC by-nc-nd)", value = 7 },
            { title = LOC "$$$/Ipernity/Dialog/License/9=Attribution+Share Alike (CC by-sa)", value = 9 },
            { title = LOC "$$$/Ipernity/Dialog/License/11=Attribution+Non Commercial+Share Alike (CC by-nc-sa)", value = 11 },
            { title = LOC "$$$/Ipernity/Dialog/License/255=Copyleft", value = 255 },
          },
        },
      },

      f:row {
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/privacy_info=You can override these settings in the metadata for each picture before export.",
          alignment = 'right',
          fill_horizontal = 1,
          size = 'mini',
        },      
      },
    },
    { 
      title = LOC "$$$/Ipernity/Dialog/albums_groups_tags=Albums, Groups and Tags",
      synopsis = bind "upload_album_synopsis",
      
      f:row {
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/albums/selected_albums=create a new album for this upload:",
          font = "<system/bold>",
        },        
      },
      
      f:row {
        f:edit_field {
          value = bind "upload_album",
          fill_horizontal = 1,
        },        
      },

      f:row {
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/albums/existing_albums=add photos to these existing albums:",
          font = "<system/bold>",
        },        
      },
      f:row {
        f:edit_field {
          value = bind "upload_album_info",
          fill_horizontal = 1,
          height_in_lines = 3,
          enabled = false,
        },        
      },
      
      f:row {        
        f:popup_menu {
          title = LOC "$$$/Ipernity/Dialog/albums/available_albums=available albums",
          value = bind 'selected_album',
          items = bind "album_list",
          width = 300,
        },
        f:push_button {
          title = "+",
          action = function ()
            add_album (property_table)
          end,
        },
        f:push_button {
          title = "-",
          action = function ()
            remove_album (property_table)
          end,
        },
        f:push_button {
          title = LOC "$$$/Ipernity/Dialog/albums/clear_list=clear list",
          action = function ()
            clear_album_list (property_table)
          end,
        },
      },
      
      f:row { 
        f:separator {
          fill_horizontal = 1,
        },
      },

      f:row {
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/groups/groups=add photos to this groups:",
          font = "<system/bold>",
        },        
      },
      
      f:row {
        f:edit_field {
          value = bind "upload_group_info",
          fill_horizontal = 1,
          height_in_lines = 3,
          enabled = false,
        },        
      },
      
      f:row {        
        f:popup_menu {
          title = LOC "$$$/Ipernity/Dialog/groups/available_groups=available groups",
          value = bind 'selected_group',
          items = bind "group_list",
          width = 300,
        },
        f:push_button {
          title = "+",
          action = function ()
            add_group (property_table)
          end,
        },
        f:push_button {
          title = "-",
          action = function ()
            remove_group (property_table)
          end,
        },
        f:push_button {
          title = LOC "$$$/Ipernity/Dialog/groups/clear_list=clear list",
          action = function ()
            clear_group_list (property_table)
          end,
        },
      },
      
      f:row { 
        f:separator {
          fill_horizontal = 1,
        },
      },    

      f:row {
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/upload_tag/add_tags=Add tags:",
          font = "<system/bold>",
          alignment = 'left',
        },
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/upload/info=Separate by comma, Tags will be combined with the exported keywords",
          alignment = 'right',
          fill_horizontal = 1,
          size = 'mini',
        },      
      },    
      f:row {
        f:edit_field{
          value = bind 'tags',
          fill_horizontal = 1,
        },
      },

    },

    -- .............................................................................................
    { 
      title = LOC "$$$/Ipernity/Dialog/auto_metadata=Advanced Upload-Settings",
      synopsis = bind "advanced_upload_synopsis",
      
      f:row {
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/albums/hint=add photos to albums:",
          font = "<system/bold>",
        },        
      },

      f:row {        
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/albums/add_public_album=add photos marked \"public\" to this album:",
          fill_horizontal = 1,
        },
        
        f:popup_menu {
          title = LOC "$$$/Ipernity/Dialog/albums/public_album=public album",
          value = bind 'public_album',
          items = bind "album_list",
          width = 300,
        },
      },

      f:row {        
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/albums/add_public_album=add photos marked \"friends\" to this album:",
          fill_horizontal = 1,
        },        
        
        f:popup_menu {
          title = LOC "$$$/Ipernity/Dialog/albums/public_album=friends album",
          value = bind 'friends_album',
          items = bind "album_list",
          width = 300,
        },
      },

      f:row {        
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/albums/add_public_album=add photos marked \"family\" to this album:",
          fill_horizontal = 1,
        },        
        
        f:popup_menu {
          title = LOC "$$$/Ipernity/Dialog/albums/public_album=family album",
          value = bind 'family_album',
          items = bind "album_list",
          width = 300,
        },
      },

      f:row {        
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/albums/add_public_album=add photos marked \"private\" to this album:",
          fill_horizontal = 1,
        },        
        
        f:popup_menu {
          title = LOC "$$$/Ipernity/Dialog/albums/private_album=private album",
          value = bind 'private_album',
          items = bind "album_list",
          width = 300,
        },
      },

      f:row {
        f:separator {
          fill_horizontal = 1,
        },
      },

      
      f:row {
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/filter/hint=add photos based on keywords to albums, groups and tags:",
          font = "<system/bold>",
        },        
      },

      f:row {
        f:checkbox {
          title = LOC "$$$/Ipernity/Dialog/albums/lightroom_album_filter=keyword-prefix",
          value = bind 'lightroom_album_filter',
          checked_value = true, unchecked_value = false,
        },
        f:edit_field{
          value = bind 'album_filter',
          width = 30,
        },
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/albums/info3=Use lightrooms keyword for adding photos to albums automatically",
          alignment = 'right',
          fill_horizontal = 1,
          size = 'mini',
        },   
      },
      
      f:row {
        f:checkbox {
          title = LOC "$$$/Ipernity/Dialog/groups/lightroom_group_filter=keyword-prefix",
          value = bind 'lightroom_group_filter',
          checked_value = true, unchecked_value = false,
        },
        f:edit_field{
          value = bind 'group_filter',
          width = 30,
        },
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/groups/info3=Use lightrooms keyword for adding photos to groups automatically",
          alignment = 'right',
          fill_horizontal = 1,
          size = 'mini',
        },   
      },

      f:row {
        f:checkbox {
          title = LOC "$$$/Ipernity/Dialog/upload_tag/lightroom_tags_filter=use keywords with prefix",
          value = bind 'lightroom_tags_filter',
          checked_value = true, unchecked_value = false,
        },
        f:edit_field{
          value = bind 'tags_filter',
          width = 30,
        },
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/upload/info3=Use only matching keyword for tagging. Prefix will be not be part of the tag",
          alignment = 'right',
          fill_horizontal = 1,
          size = 'mini',
        },   
      },
      
      f:row {
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/groups/info4=List of possible keywords:", 
        },
        f:push_button { 
          title = LOC "$$$/Ipernity/Dialog/show=show", 
          action = function() 
            function_context.postAsyncTaskWithContext( 'Call Info File',
            function( context )
              local info_file = build_keyword_list (property_table)
              local info_url = url_encode(info_file)
              info_url = string.gsub(info_url,'%%2F','/')
              info_url = string.gsub(info_url,'%%5C','/')
              info_url = string.gsub(info_url,'%%2E','.')
              info_url = string.gsub(info_url,'+','%%20')
              info_url = "file://" .. info_url
              
              local LrHttp = import 'LrHttp' 
              LrHttp.openUrlInBrowser (info_url)
            end)
          end, 
          enabled = bind "LR_canExport"
        },
        f:static_text {
          title = bind "list_progress"
        }
      },

      f:row {
        f:separator {
          fill_horizontal = 1,
        },
      },

      
      f:row {
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/tags/hint=handling of lightroom keywords:",
          font = "<system/bold>",
        },        
      },

      f:row {
        f:checkbox {
          title = LOC "$$$/Ipernity/Dialog/upload_tag/lightroom_tags=all keywords from lightroom",
          value = bind 'lightroom_tags',
          checked_value = true, unchecked_value = false,
        },
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/upload/info2=use all exported keywords for tagging",
          alignment = 'right',
          fill_horizontal = 1,
          size = 'mini',
        },      
      },
      

      f:row {
        spacing = f:control_spacing(),
        
        f:checkbox {
          title = LOC "$$$/Ipernity/Dialog/auto_tag_desc/equipment_tags=Add tags for lense and camera-body",
          value = bind 'auto_tag_equipment',
          checked_value = true, unchecked_value = false,
        },

        f:checkbox {
          title = LOC "$$$/Ipernity/Dialog/auto_tag_desc/add_settings_desc=Add exposure, focal length and ISO to the photo description",
          value = bind 'auto_desc_settings',
          checked_value = true, unchecked_value = false,
        },
      },
      
      f:row {        
        f:checkbox {
          title = LOC "$$$/Ipernity/Dialog/auto_tag_desc/date=Add a tag for the year",
          value = bind 'auto_tag_date',
          checked_value = true, unchecked_value = false,
        },
      },
      
      f:row {
        f:static_text {
          title = LOC "$$$/Ipernity/Dialog/auto_tag_desc/info=These options will be applied to the uploaded photo only. They will not change the metadata in lightroom.",
          alignment = 'right',
          fill_horizontal = 1,
          size = 'mini',
        },      
      },
    },
    
  }
  
end