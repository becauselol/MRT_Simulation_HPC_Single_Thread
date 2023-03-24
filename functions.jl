# all functions return a new event function
# The new event function adds all the events into the queue

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
			station * "_" * next,
			true,
			time,
			time
		)
	push!(s.commuters, new_commuter)

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

function train_reach_station!(;time, metro, train, station)
	# board passengers
	println("time $time: Train $train reaching Station $station")

	new_time = time + metro.stations[station].train_transit_time
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

	return [leave_station_event]
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
	for i in event_queue
		println(i)
	end
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
	for i in event_queue
		println(i)
	end
end