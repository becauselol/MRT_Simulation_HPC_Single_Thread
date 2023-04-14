function create_trains(line_code, line_duration, period, capacity, direction="FW")
	max_no = trunc(Int, line_duration / period)
	trains = Dict()
	counter = 1

	for i in 1:max_no
		trains["train_$(line_code)_$i"] = Train("train_$(line_code)_$i", line_code, direction, false, capacity, Dict())
	end

	return trains
end

function create_period_train_placement_events(line_code, line_duration, period, capacity, depot_id, direction="FW", start_time=0)
	result = Dict()
	result["events"] = []

	result["trains"] = create_trains(line_code, line_duration, period, capacity, direction)
	period = line_duration / length(result["trains"])
	time = start_time
	for train_id in keys(result["trains"])
		new_event = Event(
			time,
			train_reach_station!,
			Dict(
					:time => time,
					:train => train_id,
					:station => depot_id
				)
			)
		time += period

		push!(result["events"], new_event)
	end 


	return result
end