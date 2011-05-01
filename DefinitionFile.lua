return {
  metadataFieldsForPhotos = {
    {
      id = 'privacy',
      title = LOC "$$$/Ipernity/Dialog/Privacy/Private=Privacy",
      dataType = 'enum',
      searchable = true,
      browsable = true,
      values = {
        { value = '0', title = LOC "$$$/Ipernity/Dialog/Privacy/Private=private", },			
        { value = '1', title = LOC "$$$/Ipernity/Dialog/Privacy/Family=Family", },			
        { value = '2', title = LOC "$$$/Ipernity/Dialog/Privacy/Friends=Friends", },			
        { value = '3', title = LOC "$$$/Ipernity/Dialog/Privacy/FamilyFriends=Family & Friends", },			
        { value = '4', title = LOC "$$$/Ipernity/Dialog/Privacy/Public=public", },			
        { value = '-1', title = LOC "$$$/Ipernity/Dialog/Privacy/no_upload=don´t upload", },
        { value = nil, title = LOC "$$$/Ipernity/Dialog/Privacy/no_value=no value", },
      },		
      version = 14,
    },
    {
      id = 'ipernity_token',
      title = LOC "$$$/Ipernity/Metadata/token=token",
      dataType = "string",
      readOnly = true,
      version = 14,
    },
    {
      id = 'ipernity_id',
      title = LOC "$$$/Ipernity/Metadata/docid=document ID",
      dataType = "string",
      readOnly = true,
      version = 14,
    },
    {
      id = 'ipernity_url',
      title = LOC "$$$/Ipernity/Metadata/url=document URL",
      dataType = "url",
      readOnly = true,
      version = 14,
    },
    {
      id = 'ipernity_tags',
      title = LOC "$$$/Ipernity/Metadata/tags=ipernity tags",
      dataType = "string",
      readOnly = false,
      searchable = true,
      version = 14,
    },
    {
      id = 'ipernity_albums',
      title = LOC "$$$/Ipernity/Metadata/albums=ipernity albums",
      dataType = "string",
      readOnly = false,
      searchable = true,
      version = 14,
    },
    {
      id = 'ipernity_groups',
      title = LOC "$$$/Ipernity/Metadata/groups=ipernity groups",
      dataType = "string",
      readOnly = false,
      searchable = true,
      version = 14,
    },
    {
      id = 'ipernity_is_uploaded',
      title = LOC "$$$/Ipernity/Metadata/is_uploaded=is uploaded",
      dataType = "enum",
      values = {
        { value = true, title = LOC "$$$/Ipernity/Metadata/is_uploaded/uploaded=uploaded", },			
        { value = false, title = LOC "$$$/Ipernity/Metadata/is_uploaded/not_uploaded=not uploaded", },
        { value = nil, title = LOC "$$$/Ipernity/Metadata/is_uploaded/no_value=no value", }
      },
      readOnly = true,
      searchable = true,
      browsable = true,
      version = 15,
    },
    {
      id = 'ipernity_id_set',
      title = LOC "$$$/Ipernity/Metadata/docid_set=new document ID",
      dataType = "string",
      readOnly = false,
      version = 14,
    },
    {
      id = 'ipernity_user',
      title = LOC "$$$/Ipernity/Metadata/user=ipernity user",
      dataType = "string",
      readOnly = true,
      searchable = true,
      browsable = true,
      version = 14,
    },
  },
  schemaVersion = 1,
}