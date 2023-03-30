using HDF5, Dates

function store_final_data(data, duration)
	fid = h5open("data/runsData.h5", "w") 
	group_name = "dataset_d_$(duration)_run_$(now())"
	create_group(fid, group_name)

	group = fid[group_name]

	wait_times = create_group(group, "wait_times")

	for (k, v) in data.wait_times
		wait_times[k] = v 
	end

	travel_times = create_group(group, "travel_times")

	for (origin, v) in data.travel_times
		origin_group = create_group(travel_times, origin)
		for (dest, arr) in v 
			origin_group[dest] = arr
		end 
	end

	station_commuter_count = create_group(group, "station_commuter_count")

	for (k,v) in data.station_commuter_count
	    station = create_group(station_commuter_count, k)
	    station["count"] = v[!, "count"]
	    station["time"] = v[!, "time"]
	    station["event"] = v[!, "event"]
	end

	station_train_commuter_count = create_group(group, "station_train_commuter_count")

	for (k,v) in data.station_train_commuter_count
	    station = create_group(station_train_commuter_count, k)
	    station["count"] = v[!, "count"]
	    station["time"] = v[!, "time"]
	    station["event"] = v[!, "event"]
	end

	close(fid)
end

