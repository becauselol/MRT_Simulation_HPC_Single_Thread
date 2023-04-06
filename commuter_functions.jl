using Distributions

function create_spawn_events(spawn_labels, spawn_rates, station_name_id_map)
	events = []

	for (i, i_name) in enumerate(spawn_labels)
		for (j, j_name) in enumerate(spawn_labels)
			if i_name == j_name
				continue
			end 

			rate = spawn_rates[i, j]

			if rate == 0
				continue
			end

			new_time = rand(Exponential(rate), 1)[1]

			i_id = station_name_id_map[i_name]
			j_id = station_name_id_map[j_name]

			new_event = Event(
					new_time,
					spawn_commuter!,
					Dict(
							:time => new_time,
							:rate => rate,
							:station => i_id,
							:target => j_id
						)
				)
			push!(events, new_event)
		end 
	end 

	return events
end