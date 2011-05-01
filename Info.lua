---------------------------------------------------------------------------------------------------
return {
	LrSdkVersion = 2.0,

	LrToolkitIdentifier = 'de.heideweg9.iper4lr',
	LrPluginName = LOC "$$$/Ipernity/ipernity_for_lightroom=Ipernity for Lightroom",
	
--	LrInitPlugin = 'Globals.lua',
--	LrPluginInfoProvider = 'GlobalDialog.lua',
	
	LrMetadataProvider = 'DefinitionFile.lua',
	
	LrMetadataTagsetFactory = 'Tagset.lua',
	
	LrLibraryMenuItems = {
	  {
		title = LOC "$$$/Ipernity/get_ipernity=get metadata from Ipernity", 
		file = 'UpdateFromIpernity.lua',
		enabledWhen = "photosAvailable",
      },
	  {
		title = LOC "$$$/Ipernity/unlink=unlink from ipernity", 
		file = 'RemoveIpernityLink.lua', 
		enabledWhen = "photosAvailable",
      },
 	}, 

	LrExportServiceProvider = {
		title = LOC "$$$/Ipernity/Ipernity_upload=upload to Ipernity",
		file = 'IpernityUpload.lua',
	},

	VERSION = { major=1, minor=0, revision=0, build=20090321, },
}