function get_neighbour_id(station, line_code, direction)
	values = get(station.neighbours[line_code], direction, nothing)
	if values == nothing
		return nothing
	end 
	return values[1]
end

function get_neighbour_weight(station, line_code, direction)
	values = get(station.neighbours[line_code], direction, nothing)
	if values == nothing
		return nothing
	end 
	return values[2]
end


function add_commuter_to_station!(time, metro, station, commuter)
	if !haskey(station.commuters, "waiting")
		station.commuters["waiting"] = []
	end

	push!(station.commuters["waiting"], commuter)

	station_count = Station_Commuter_Count(station.station_id, time, "post_spawn", get_number_commuters(station))

	return Dict(
			"station_count" => station_count
		)
end

function remove_commuter_from_station!(time, metro, station)
	travel_time_update = Inter_Station_Time_Update(station.station_id, Dict())
	perc_wait_time_update = Inter_Station_Time_Update(station.station_id, Dict())
	
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

		perc_wait = round(commuter.total_wait_time/travel_time, digits=2)

		if !haskey(perc_wait_time_update.update, origin)
			perc_wait_time_update.update[origin] = []
		end
		push!(perc_wait_time_update.update[origin], perc_wait)
	end

	@debug "time $(round(time; digits=2)): terminating $(size(station.commuters["terminating"])[1]) commuters at Station $(station.station_id)"

	station.commuters["terminating"] = []

	station_count = Station_Commuter_Count(station.station_id, time, "post_terminate", get_number_commuters(station))

	return Dict(
			"travel_time" => travel_time_update,
			"perc_wait_time" => perc_wait_time_update,
			"station_count" => station_count
		)
end

function board_commuters!(time, metro, train, station)
	train_number = get_number_commuters(train)
	train_count = Train_Commuter_Count(station.station_id, time, "pre_board", train_number)
	wait_time_update = Wait_Time_Update(station.station_id, [])

	line = train.line
	direction = train.direction
	line_direction = line * "_" * direction

	if !haskey(station.commuters, line_direction)
		station.commuters[line_direction] = []
	end

	board_count = 0

	board_indexes = []

	if !(haskey(station.commuters, "waiting"))
		station.commuters["waiting"] = []
		return Dict()
	end

	for (i, commuter) in enumerate(station.commuters["waiting"])
		if train_number + board_count > train.capacity
			break
		end

		wait_time = time - commuter.wait_start
		push!(wait_time_update.update, wait_time)

		# add to commuters wait time
		commuter.total_wait_time += wait_time

		options = keys(metro.paths[station.station_id][commuter.target])

		if line_direction in options
			push!(board_indexes, i)
		end
		board_count += 1
	end
	
	for i in reverse(board_indexes)
		commuter = splice!(station.commuters["waiting"], i)

		alight_choices = metro.paths[station.station_id][commuter.target][line_direction]
		choice = rand(alight_choices)

		if !haskey(train.commuters, choice)
			train.commuters[choice] = []
		end 

		push!(train.commuters[choice], commuter)
	end

	@debug "time $(round(time; digits=2)): $board_count Commuters boarding Train $(train.train_id) at Station $(station.station_id)"

	station_count = Station_Commuter_Count(station.station_id, time, "post_board", get_number_commuters(station))

	return Dict(
			"train_count" => train_count,
			"station_count" => station_count,
			"wait_time" => wait_time_update
		)
end

function alight_commuters!(time, metro, train, station)
	train_count = Train_Commuter_Count(station.station_id, time, "pre_alight", get_number_commuters(train))

	alight_count = 0

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
 		else 
 			if !haskey(station.commuters, "waiting")
 				station.commuters["waiting"] = []
 			end
 			push!(station.commuters["waiting"], commuter)
		end

		alight_count += 1
	end

	@debug "time $(round(time; digits=2)): $alight_count Commuters alighting Train $(train.train_id) at Station $(station.station_id)"
	
	station_count = Station_Commuter_Count(station.station_id, time, "post_alight", get_number_commuters(station))

	return Dict(
			"train_count" => train_count,
			"station_count" => station_count
		)
end

