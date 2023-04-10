using Distributions

function create_spawn_events!(spawn_data_file_path, station_dict, start_spawn_time)
	events = []

	code_map = create_station_code_map(station_dict)
	spawn_data_csv = CSV.File(spawn_data_file_path, header=false)

	for row in spawn_data_csv
		hour = convert(Int64, row[1])
		if hour == 0
			continue
		end
		from_code = String(row[2])
		to_code = String(row[3])
		rate = convert(Float64, (row[4]/60))

		if (!haskey(code_map, from_code) || !haskey(code_map, to_code))
			continue
		end
		from_id = code_map[from_code]
		to_id = code_map[to_code]

		from_station = station_dict[from_id]
		if !haskey(from_station.spawn_rate, to_id)
			from_station.spawn_rate[to_id] = Dict()
		end

		from_station.spawn_rate[to_id][hour] = rate
	end

	start_hour = convert(Int32, floor(start_spawn_time/60))

	for (i_id, i_station) in station_dict
		for (j_id, j_station) in station_dict
			if i_id == j_id
				continue
			end 

			if !haskey(i_station.spawn_rate, j_id)
				continue
			end

			if !haskey(i_station.spawn_rate[j_id], start_hour)
				station_start_spawn_hour = minimum(keys(i_station.spawn_rate[j_id]))
				station_start_spawn_time = station_start_spawn_hour * 60
			else
				station_start_spawn_hour = start_hour
				station_start_spawn_time = start_spawn_time
			end

			rate = i_station.spawn_rate[j_id][station_start_spawn_hour]

			

			new_time = rand(Exponential(1/rate), 1)[1] + station_start_spawn_time

			new_event = Event(
					new_time,
					spawn_commuter!,
					Dict(
							:time => new_time,
							:station => i_id,
							:target => j_id
						)
				)
			push!(events, new_event)
		end 
	end 

	return events
end