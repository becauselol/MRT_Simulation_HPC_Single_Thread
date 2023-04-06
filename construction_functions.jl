function construct_station_dict(station_string)
	station_count = 1

	station_data = Dict()

	# for each station in station_string
	for station_details in eachsplit(station_string, "\n")
    	station_arr = String.(split(station_details, ","))

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

function construct_station_name_id_map(station_dict)
	name_id_map = Dict()
	for (station_id, station) in station_dict 
		name_id_map[station.name] = station_id 
	end 
	return name_id_map
end

function create_station_code_map(station_dict)
	code_map = Dict()
	for (station_id, station) in station_dict 
		for code in station.stationCodes
			code_map[code] = station_id
		end
	end
	return code_map
end

function construct_edges_from_edges_dict!(station_dict, edges_dict)
	# create code mapping for stations
	code_map = create_station_code_map(station_dict)
	start_station_dict = Dict()
	for (line_code, edges_string) in edges_dict
		start_station_id = construct_edges_for_line!(line_code, edges_string, station_dict, code_map)
		start_station_dict[line_code] = start_station_id
	end

	return start_station_dict
end

function add_station_neighbour!(from_station, to_station_id, line, direction, weight)
    if !(line in keys(from_station.neighbours))
        from_station.neighbours[line] = Dict()
    end
	from_station.neighbours[line][direction] = [to_station_id, weight]
end

function construct_edges_for_line!(line_code, edges_string, station_dict, code_map)
	# for each station in station_string
	all_edges_details = collect(eachsplit(edges_string, "\n"))
	first_edge = all_edges_details[1]
	first_station = String.(split(first_edge, ","))[1]

	for edge_details in eachsplit(edges_string, "\n")
    	edge_arr = String.(split(edge_details, ","))

    	from_station_code = String(edge_arr[1])
    	to_station_code = String(edge_arr[2])
    	time_taken = parse(Float64, edge_arr[3])

    	from_station_id = code_map[from_station_code]
    	to_station_id = code_map[to_station_code]

    	from_station = station_dict[from_station_id]
    	to_station = station_dict[to_station_id]

    	add_station_neighbour!(from_station, to_station_id, line_code, "FW", time_taken)
    	add_station_neighbour!(to_station, from_station_id, line_code, "BW", time_taken)
	end

	return code_map[first_station]
end

function construct_lines_from_start_stations(station_dict, start_stations)
	lines = Dict()

	for (line_code, start_station_id) in start_stations 
		lines[line_code] = Dict()

		lines[line_code]["FW"] = [start_station_id]

		curr_id = start_station_id
		curr = station_dict[curr_id]

		next_id = get_neighbour_id(curr, line_code, "FW")

		while next_id != nothing
			next = station_dict[next_id]
			push!(lines[line_code]["FW"], next_id)
			curr = next
			next_id = get_neighbour_id(curr, line_code, "FW")
		end

		lines[line_code]["BW"] = reverse(lines[line_code]["FW"])
	end

	return lines
end


function construct_commuter_graph(station_dict)
	commuter_edge_dict = Dict()
	commuter_node_list = []

	for (station_id, station) in station_dict 
		for code in station.codes
			push!(commuter_node_list, "$(station_id).$(code)")
			commuter_edge_dict["$(station_id).$(code)"] = Dict()
		end 

		for iCode in station.codes
			for jCode in station.codes
				if iCode == jCode
					continue
				end 

				commuter_edge_dict["$(station_id).$(iCode)"]["$(station_id).$(jCode)"] = 0.1
			end 
		end 

		for (line, line_dict) in station.neighbours
			for (direction, values) in line_dict 
				commuter_edge_dict["$(station_id).$(line)"]["$(values[1]).$(line)"] = values[2] + station.train_transit_time
			end 	
		end 
	end 

	return CommuterGraph(commuter_node_list, commuter_edge_dict)
end 