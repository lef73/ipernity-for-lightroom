--[[----------------------------------------------------------------------------
IperUploadProvider.lua
iperupload.lrdevplugin
--------------------------------------------------------------------------------
 Copyright 2009 Dirk Festerling
 All Rights Reserved.
 
 Based on the SDK-example for exporting to flickr.
------------------------------------------------------------------------------]]

-- Lightroom SDK
--local LrColor = import "LrColor"
-- Flickr plug-in
require "Dialog"
require "IpernityUploadTask"

return { 
	hideSections = {'exportLocation','metadata','fileNaming'},
	allowFileFormats = {'JPEG'},
	allowColorSpaces = {'sRGB'},
	hidePrintResolution = true,

    exportPresetFields = {
        { key = "token" },
        { key = "user_id", default = "" },
        { key = "ipernity_id", default = "n.n." },
        { key = "public", default = 0 },
        { key = "family", default = 0 },
        { key = "friends", default = 0 },
        { key = "license", default = 0 },
        { key = "auto_tag_equipment", default = false },
        { key = "auto_desc_settings", default = false },
        { key = "auto_tag_date", default = false },
        { key = "tags", default = "" },
        { key = "lightroom_tags", default = false },
        { key = "tags_filter", default = "ip:" },
        { key = "lightroom_tags_filter", default = false },
        { key = "album_filter", default = "ia:" },
        { key = "lightroom_album_filter", default = false },
        { key = "upload_album_ids", default = {} },
        { key = "upload_album_info", default = "" },
        { key = "group_filter", default = "ig:" },
        { key = "lightroom_group_filter", default = false },
        { key = "upload_group_ids", default = {} },
        { key = "upload_group_info", default = "" },
        { key = "public_album", default = "" },
        { key = "friends_album", default = "" },
        { key = "family_album", default = "" },
        { key = "private_album", default = "" },
        
    },		

	startDialog = Dialog.start_dialog,
	sectionsForTopOfDialog = Dialog.export_top_sections,

--	sectionsForBottomOfDialog = IpernityExportDialogSections.export_bottom_sections,

	processRenderedPhotos = IpernityUploadTask.process_rendered_photos,	
} 
