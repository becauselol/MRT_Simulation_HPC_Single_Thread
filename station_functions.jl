function add_commuter_to_station!(metro, station, commuter)
	chosen_path = metro.paths[station.station_id][commuter.target]
	if !haskey(station.commuters, chosen_path["board"])
		station.commuters[chosen_path["board"]] = []
	end
	push!(station.commuters[chosen_path["board"]], commuter)
end

function remove_commuter_from_station!(metro, station)
	if !haskey(station.commuters, "terminating")
		station.commuters["terminating"] = []
		return 0
	end
	count = size(station.commuters["terminating"])[1]
	station.commuters["terminating"] = []

	return count
end

function board_commuters!(metro, train, station)
	count = 0 

	line = train.line
	direction = train.direction
	line_direction = line * "_" * direction

	if !haskey(station.commuters, line_direction)
		station.commuters[line_direction] = []
		return 0
	end

	while get_number_commuters(train) < train.capacity && size(station.commuters[line_direction])[1] > 0
		commuter = popfirst!(station.commuters[line_direction])

		chosen_path = metro.paths[station.station_id][commuter.target]

		if !haskey(train.commuters, chosen_path["alight"])
			train.commuters[chosen_path["alight"]] = []
		end
		push!(train.commuters[chosen_path["alight"]], commuter)

		count += 1
	end

	return count 
end

function alight_commuters!(metro, train, station)
	count = Dict(
			"interchange" => 0,
			"terminating" => 0,
			"total" => 0
		)

	if !haskey(train.commuters, station.station_id)
		train.commuters[station.station_id] = []
		return count
	end
	while size(train.commuters[station.station_id])[1] > 0
		commuter = popfirst!(train.commuters[station.station_id])
		if commuter.target == station.station_id
			if !haskey(station.commuters, "terminating")
				station.commuters["terminating"] = []
			end
			push!(station.commuters["terminating"], commuter)

			count["terminating"] += 1
			count["total"] += 1
 			continue
		end

		count["total"] += 1
	end

	return count 
end

