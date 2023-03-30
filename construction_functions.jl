function process_station_string(station_string)
	station_count = 1

	station_data = Dict()

	# for each station in station_string
	for station_details in eachsplit(station_string, "\n")
    	station_arr = String.(split(station_details, ","))
        println(station_arr)
    	station_name = String(station_arr[1])

    	stationCodes = []
        for c in eachsplit(station_arr[2], "/")
            push!(stationCodes, String(c))
        end

    	lineCodes = []
    	for c in stationCodes
    		push!(lineCodes, String(first(c,3)))
    	end

    	station_data["station_$station_count"] = Station(
    			"station_$station_count",
				lineCodes,
				station_name,
				stationCodes
    		)

    	station_count += 1
	end

	return station_data
end