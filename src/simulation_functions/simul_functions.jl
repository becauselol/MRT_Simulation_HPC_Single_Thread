# all functions return a new event function
# The new event function adds all the events into the queue
function spawn_commuter!(;time, metro, station, target)
	
	s = metro.stations[station]

	@debug "time $(round(time; digits=2)): spawning commuter at Station $station that wants to go to $target"
	new_commuter = Commuter(
			station,
			target,
			true,
			time,
			time,
			0
		)

	start_hour = convert(Int32, floor(time/60))

	new_time = Inf
	# @info "$station $target"

	for hour in start_hour:23

		if !haskey(s.spawn_rate[target], hour)
			continue
		end
		if hour == start_hour	
			station_start_spawn_time = time
		else 
			station_start_spawn_time = hour * 60
		end

		rate = s.spawn_rate[target][hour]

		new_time = station_start_spawn_time + rand(Exponential(1/rate), 1)[1]
		if convert(Int64, floor(new_time/60)) <= hour
			break
		else
			new_time = Inf
			continue 
		end 
	end
	
	if new_time == Inf
		return Dict() 
	end

	data_update = add_commuter_to_station!(time, metro, s, new_commuter)

	next_spawn_event = Event(
			new_time,
			spawn_commuter!,
			Dict(
					:time => new_time,
					:station => station,
					:target => target
				)
		)

	return Dict(
			"data_store" => data_update,
			"new_events" => [next_spawn_event]
		)
end

function terminate_commuters!(;time, metro, station)
	s = metro.stations[station]
	
	data_update = remove_commuter_from_station!(time, metro, s)
	
	return Dict(
			"data_store" => data_update
		)
end

function train_reach_station!(;time, metro, train, station)
	events = []
	t = metro.trains[train]
	s = metro.stations[station]

	line = t.line
	direction = t.direction 

	# we need to change direction here so people know to board
	line_dict = get(s.neighbours, line, nothing)
	next_station = get(line_dict, direction, nothing)

	# changes direction
	if next_station == nothing
		if direction == "FW"
			direction = "BW"
		else 
			direction = "FW"
		end

		t.direction = direction
	end

	# alight and board passengers
	@debug "time $(round(time; digits=2)): Train $train reaching Station $station"

	data_update = alight_commuters!(time, metro, t, s)
	
	new_time = time + metro.stations[station].train_transit_time

	# if any terminating passengers
	if size(s.commuters["terminating"])[1] > 0
		terminate_commuters = Event(
			new_time,
			terminate_commuters!,
			Dict(
					:time => new_time,
					:station => station,
				)
		)
		push!(events, terminate_commuters)
	end

	# create leave station event
	leave_station_event = Event(
			new_time,
			train_leave_station!,
			Dict(
					:time => new_time,
					:train => train,
					:station => station
				)
		)
	push!(events, leave_station_event)
	return Dict(
			"data_store" => data_update,
			"new_events" => events
		)
end

function train_leave_station!(;time, metro, train, station)
	@debug "time $time: Train $train leaving  Station $station"
	t = metro.trains[train]
	s = metro.stations[station]

	line = t.line
	direction = t.direction 

	line_dict = get(s.neighbours, line, nothing)

	next_station = get(line_dict, direction, nothing)
	# changes direction
	if next_station == nothing
		if direction == "FW"
			direction = "BW"
		else 
			direction = "FW"
		end

		t.direction = direction

		next_station = get(line_dict, direction, nothing)

	end

	data_update = board_commuters!(time, metro, t, s)

	new_time = time + next_station[2]
	reach_station_event = Event(
			new_time,
			train_reach_station!,
			Dict(
					:time => new_time,
					:train => train,
					:station => next_station[1]
				)
		)

	return Dict(
			"data_store" => data_update,
			"new_events" => [reach_station_event]
		)
end


function simulate!(max_time, metro, event_queue, data_store)
	update_function = Dict(
			"train_count" => update_train_count!,
			"station_count" => update_station_count!,
			"travel_time" => update_travel_time!,
			"wait_time" => update_wait_time!,
			"perc_wait_time" => update_perc_wait_time!
		)
	curr_min = convert(Int64, floor(event_queue[1].time/60))
	@info "$(now()): start time is $curr_min"

	events_simulated = 0
	while event_queue[1].time < max_time
		# release the most recent event
		curr_event = heappop!(event_queue)
		events_simulated += 1

		if convert(Int64, floor(event_queue[1].time/60)) != curr_min
			curr_min = convert(Int64, floor(event_queue[1].time/60))

			@info "processed $(events_simulated) events"
			@info "$(now()): time is now $curr_min"
			@info "size of event queue $(size(event_queue)[1])"

			# events_processed = 0
		end
		# do whatever the event requires
		update = curr_event.fun(;curr_event.params..., metro=metro)

		# update the various statistics
		data_update = get(update, "data_store", Dict())
		for (k, v) in data_update
			update_fun = update_function[k]
			update_fun(data_store, v)
		end
		# add_data_stores!(data_store, data_store_update)

		# update and add the new events generated
		new_events = get(update, "new_events", [])
		for i in new_events
			heappush!(event_queue, i)
		end
	end

	return data_store
end