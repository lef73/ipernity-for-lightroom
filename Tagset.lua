--[[----------------------------------------------------------------------------
MyMetadataTagset.lua
MyMetadata.lrplugin
--------------------------------------------------------------------------------
ADOBE SYSTEMS INCORPORATED
 Copyright 2008 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.
------------------------------------------------------------------------------]]
return{
  {
    title = LOC "$$$/Ipernity/Ipernity=Ipernity",
    id = 'i4lTagset',
    
    items = {
      { 'com.adobe.label', label = LOC "$$$/Ipernity/Ipernity=Ipernity" }, 
      'com.adobe.title', 
       { 'com.adobe.caption', height_in_lines = 6 }, 		 
      'com.adobe.copyright',
      'de.heideweg9.iper4lr.privacy',
      'de.heideweg9.iper4lr.ipernity_url',
      'de.heideweg9.iper4lr.ipernity_user',
      
      'com.adobe.separator',
      { 'com.adobe.label', label = LOC "$$$/Ipernity/Metadata/Read=Tags, Groups & Albums" }, 
      'de.heideweg9.iper4lr.ipernity_tags',
      'de.heideweg9.iper4lr.ipernity_albums',
      'de.heideweg9.iper4lr.ipernity_groups',
      { 'com.adobe.label', label = LOC "$$$/Ipernity/Metadata/DontEdit1=Do not edit this data -" }, 
      { 'com.adobe.label', label = LOC "$$$/Ipernity/Metadata/DontEdit2=Use the Update-Function instead!" }, 
    },
  },
  {
    title = LOC "$$$/Ipernity/Link=Link to Ipernity",
    id = 'i4lLink',
    
    items = {
      'com.adobe.separator',
      { 'com.adobe.label', label = LOC "$$$/Ipernity/newIpernityID=New Ipernity-ID" }, 
      'de.heideweg9.iper4lr.ipernity_id_set',      
      { 'com.adobe.label', label = LOC "$$$/Ipernity/Metadata/Link1=Enter document ID here and" }, 
      { 'com.adobe.label', label = LOC "$$$/Ipernity/Metadata/Link2=update/export this photo to"}, 
      { 'com.adobe.label', label = LOC "$$$/Ipernity/Metadata/Link3=link it to an existing document." }, 
    },
  }

}