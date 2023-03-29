# all functions return a new event function
# The new event function adds all the events into the queue
include("station_functions.jl")
include("utility_functions.jl")
include("data_store_functions.jl")

function spawn_commuter!(;time, metro, station)
	
	s = metro.stations[station]

	options = collect(keys(metro.stations))
	deleteat!(options, findall(x->x==s.station_id,options))
	
	next = rand(options)
	@debug "time $time: spawning commuter at Station $station that wants to go to $next"
	new_commuter = Commuter(
			station,
			next,
			true,
			time,
			time
		)

	data_update = add_commuter_to_station!(time, metro, s, new_commuter)

	new_time = time + s.spawn_rate
	next_spawn_event = Event(
			new_time,
			spawn_commuter!,
			Dict(
					:time => new_time,
					:station => station
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

	line_direction = line * "_" * direction

	# we need to change direction here so people know to board
	next_station = get(s.neighbours, line_direction, nothing)
	# changes direction
	if next_station == nothing
		if direction == "fw"
			direction = "bw"
		else 
			direction = "fw"
		end

		line_direction = line * "_" * direction
		t.direction = direction
	end

	# alight and board passengers
	@debug "time $time: Train $train reaching Station $station"

	data_update = alight_commuters!(time, metro, t, s)
	
	new_time = time + metro.stations[station].train_transit_time

	# if any terminating passengers
	if size(s.commuters["terminating"])[1] > 0
		terminate_commuters = Event(
			time,
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

	line_direction = line * "_" * direction

	next_station = get(s.neighbours, line_direction, nothing)
	# changes direction
	if next_station == nothing
		if direction == "fw"
			direction = "bw"
		else 
			direction = "fw"
		end

		line_direction = line * "_" * direction
		t.direction = direction

		next_station = get(s.neighbours, line_direction, nothing)
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
			"wait_time" => update_wait_time!
		)

	while event_queue[1].time < max_time
		# release the most recent event
		curr_event = heappop!(event_queue)
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