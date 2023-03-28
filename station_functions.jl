function add_commuter_to_station!(time, metro, station, commuter)

	chosen_path = metro.paths[station.station_id][commuter.target]
	if !haskey(station.commuters, chosen_path["board"])
		station.commuters[chosen_path["board"]] = []
	end
	push!(station.commuters[chosen_path["board"]], commuter)

	station_count = Station_Commuter_Count(station.station_id, time, "post_spawn", get_number_commuters(station))

	return Dict(
			"station_count" => station_count
		)
end

function remove_commuter_from_station!(time, metro, station)
	travel_time_update = Travel_Time_Update(station.station_id, Dict())
	
	if !haskey(station.commuters, "terminating")
		station.commuters["terminating"] = []
	end

	for commuter in station.commuters["terminating"]
		# we need to update travel time
		origin = commuter.origin

		travel_time = time - commuter.spawn_time
		if !haskey(travel_time_update.update, origin)
			travel_time_update.update[origin] = []
		end
		push!(travel_time_update.update[origin], travel_time)
	end

	station.commuters["terminating"] = []

	station_count = Station_Commuter_Count(station.station_id, time, "post_terminate", get_number_commuters(station))

	return Dict(
			"travel_time" => travel_time_update,
			"station_count" => station_count
		)
end

function board_commuters!(time, metro, train, station)
	train_count = Train_Commuter_Count(station.station_id, time, "pre_board", get_number_commuters(train))
	wait_time_update = Wait_Time_Update(station.station_id, [])

	line = train.line
	direction = train.direction
	line_direction = line * "_" * direction

	if !haskey(station.commuters, line_direction)
		station.commuters[line_direction] = []
	end

	while get_number_commuters(train) < train.capacity && size(station.commuters[line_direction])[1] > 0
		commuter = popfirst!(station.commuters[line_direction])

		# update the wait_time_update
		wait_time = time - commuter.wait_start
		push!(wait_time_update.update, wait_time)

		# find the path it needs to go
		chosen_path = metro.paths[station.station_id][commuter.target]

		if !haskey(train.commuters, chosen_path["alight"])
			train.commuters[chosen_path["alight"]] = []
		end
		# board the commuter
		push!(train.commuters[chosen_path["alight"]], commuter)
	end

	station_count = Station_Commuter_Count(station.station_id, time, "post_board", get_number_commuters(station))

	return Dict(
			"train_count" => train_count,
			"station_count" => station_count,
			"wait_time" => wait_time_update
		)
end

function alight_commuters!(time, metro, train, station)
	train_count = Train_Commuter_Count(station.station_id, time, "pre_alight", get_number_commuters(train))

	if !haskey(train.commuters, station.station_id)
		train.commuters[station.station_id] = []
	end

	if !haskey(station.commuters, "terminating")
		station.commuters["terminating"] = []
	end
	while size(train.commuters[station.station_id])[1] > 0
		commuter = popfirst!(train.commuters[station.station_id])
		commuter.wait_start = time
		if commuter.target == station.station_id
			
			push!(station.commuters["terminating"], commuter)

 			continue
		end
	end

	station_count = Station_Commuter_Count(station.station_id, time, "post_alight", get_number_commuters(station))

	return Dict(
			"train_count" => train_count,
			"station_count" => station_count
		)
end

