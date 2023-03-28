function get_number_commuters(obj)
	# REQUIRE obj to have attribute commuters
	count = 0
	for (key, value) in obj.commuters
	    count += size(value)[1]
	end
	return count
end
