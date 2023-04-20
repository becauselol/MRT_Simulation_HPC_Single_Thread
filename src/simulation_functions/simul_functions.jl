# all functions return a new event function
# The new event function adds all the events into the queue
function spawn_commuter!(;time, metro, station, target, max_rate)
	
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

	hour = convert(Int32, floor(time/60))

	if (rand() <= s.spawn_rate[target][hour]/max_rate)
		data_update = add_commuter_to_station!(time, metro, s, new_commuter)
		count = 1
	else 
		count = 0
	end 

	new_time = time + rand(Exponential(1/max_rate), 1)[1]

	next_spawn_event = Event(
			new_time,
			spawn_commuter!,
			Dict(
					:time => new_time,
					:station => station,
					:target => target,
					:max_rate => max_rate
				)
		)

	return Dict(
			"spawn_count" => count,
			"new_events" => [next_spawn_event]
		)
end

function terminate_commuters!(;time, metro, station)
	s = metro.stations[station]
	
	data_update = remove_commuter_from_station!(time, metro, s)
	
	return Dict(
			"term_count"=> data_update
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

	alight_commuters!(time, metro, t, s)
	
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

	board_commuters!(time, metro, t, s)

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
			"new_events" => [reach_station_event]
		)
end


function simulate!(max_time, metro, event_queue)

	curr_min = convert(Int64, floor(peek(event_queue)[1].time/60))
	# @info "$(now()): start time is $curr_min"

	cum_term = 0
	cum_spawn = 0

	events_simulated = 0
	while peek(event_queue)[1].time < max_time
		# release the most recent event
		curr_event = dequeue!(event_queue)
		events_simulated += 1
		update = curr_event.fun(;curr_event.params..., metro=metro)

		# add_data_stores!(data_store, data_store_update)
		cum_spawn += get(update, "spawn_count", 0)
		cum_term += get(update, "term_count", 0)

		# update and add the new events generated
		new_events = get(update, "new_events", [])
		for i in new_events
			enqueue!(event_queue, i, i.time)
		end
	end
	@info "spawned: $(cum_spawn), terminated: $(cum_term)"
	return 
end