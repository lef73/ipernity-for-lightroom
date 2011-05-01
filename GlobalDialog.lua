return {
	sectionsForTopOfDialog = function (f, property_table )
		return {  
			{
				title = LOC "$$$/Ipernity/Dialog/Account=Ipernity Account",
				synopsis = "Test",
				f:row {
					f:edit_field {
						-- title = bind 'ipernity_id',
						value = _G.test,
						alignment = 'left',
						fill_horizontal = 1,
					},
				},
			}
		}
	end
}
