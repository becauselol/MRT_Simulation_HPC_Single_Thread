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
		from_codes = String(row[2])
		from_code_arr = String.(split(from_codes, "/"))
		from_id = nothing
		for code in from_code_arr
			if haskey(code_map, code)
				from_id = code_map[code]
				break
			end
		end


		to_codes = String(row[3])
		to_code_arr = String.(split(to_codes, "/"))
		to_id = nothing
		for code in to_code_arr
			if haskey(code_map, code)
				to_id = code_map[code]
				break
			end
		end

		rate = convert(Float64, (row[4]/60))

		if (from_id == nothing || to_id == nothing)
			continue
		end

		from_station = station_dict[from_id]
		if !haskey(from_station.spawn_rate, to_id)
			from_station.spawn_rate[to_id] = Dict()
		end

		from_station.spawn_rate[to_id][hour] = rate
	end

	start_hour = convert(Int64, floor(start_spawn_time/60))

	for (i_id, i_station) in station_dict
		for (j_id, j_station) in station_dict
			if i_id == j_id
				continue
			end 

			if !haskey(i_station.spawn_rate, j_id)
				continue
			end

			new_time = Inf
			# @info "$station $target"

			for hour in start_hour:23
				if !haskey(i_station.spawn_rate[j_id], hour)
					continue
				end
				if hour == start_hour	
					station_start_spawn_time = start_spawn_time
				else 
					station_start_spawn_time = hour * 60
				end

				rate = i_station.spawn_rate[j_id][hour]

				new_time = station_start_spawn_time + rand(Exponential(1/rate), 1)[1]

				if convert(Int64, floor(new_time/60)) <= hour
					break
				else
					new_time = Inf
					continue 
				end 
			end

			if new_time == Inf
				continue
			end

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