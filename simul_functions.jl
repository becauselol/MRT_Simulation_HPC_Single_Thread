# all functions return a new event function
# The new event function adds all the events into the queue
include("station_functions.jl")
include("utility_functions.jl")

function spawn_commuter!(;time, metro, station)
	println("time $time: spawning commuter at Station $station")
	s = metro.stations[station]

	if station == "a"
		next = "c"
	elseif station == "b"
		next = "a"
	elseif station == "c"
		next = "a"
	end

	new_commuter = Commuter(
			station,
			next,
			true,
			time,
			time
		)

	add_commuter_to_station!(metro, s, new_commuter)

	new_time = time + s.spawn_rate
	next_spawn_event = Event(
			new_time,
			spawn_commuter!,
			Dict(
					:time => new_time,
					:metro => metro,
					:station => station
				)
		)

	return [next_spawn_event]
end

function terminate_commuters!(;time, metro, station)
	s = metro.stations[station]

	count = remove_commuter_from_station!(metro, s)
	println("time $time: removing $count commuters from Station $station")

	return []
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
	println("time $time: Train $train reaching Station $station")

	a_count = alight_commuters!(metro, t, s)
	alight_count = a_count["total"]
	println("time $time: $alight_count Commuters alighting Train $train at Station $station")

	count = board_commuters!(metro, t, s)
	println("time $time: $count Commuters boardng Train $train at Station $station")

	
	new_time = time + metro.stations[station].train_transit_time

	# if any terminating passengers
	if a_count["terminating"] > 0
		terminate_commuters = Event(
			time,
			terminate_commuters!,
			Dict(
					:time => new_time,
					:metro => metro,
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
					:metro => metro,
					:train => train,
					:station => station
				)
		)
	push!(events, leave_station_event)
	return events
end

function train_leave_station!(;time, metro, train, station)
	println("time $time: Train $train leaving  Station $station")
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

	new_time = time + next_station[2]
	reach_station_event = Event(
			new_time,
			train_reach_station!,
			Dict(
					:time => new_time,
					:metro => metro,
					:train => train,
					:station => next_station[1]
				)
		)

	return [reach_station_event]
end


function simulate!(max_time, metro, event_queue)
	while event_queue[1].time < max_time
		# release the most recent event
		curr_event = heappop!(event_queue)
		# do whatever the event requires
		new_events = curr_event.fun(;curr_event.params...)
		# update and add the new events generated
		for i in new_events
			heappush!(event_queue, i)
		end
	end
end