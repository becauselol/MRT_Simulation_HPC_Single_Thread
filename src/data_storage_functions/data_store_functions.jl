struct Station_Commuter_Count
	station_id::String 
	time::Float64
	event::String
	count::Float64
end

struct Train_Commuter_Count
	station_id::String 
	time::Float64
	event::String
	count::Float64
end

struct Wait_Time_Update
	station_id::String
	update::Vector{Float64}
end

struct Inter_Station_Time_Update
	target_id::String
	update::Dict{String, Vector{Any}} # key is origin_id, value is the travel time
end

mutable struct Data_Store
	wait_times::Dict{String, Vector{Float64}}
	percentage_wait_time::Dict{String, Dict{String, Vector{Float64}}}
	travel_times::Dict{String, Dict{String, Vector{Float64}}}
	station_commuter_count::Dict{String, DataFrame}
	station_train_commuter_count::Dict{String, DataFrame}
end

function update_train_count!(data_store, update)
	update_df = DataFrame(time=update.time, event=update.event, count=update.count)
	if !haskey(data_store.station_train_commuter_count, update.station_id)
		data_store.station_train_commuter_count[update.station_id] = update_df
		return
	end
	append!(data_store.station_train_commuter_count[update.station_id], update_df)
end

function update_station_count!(data_store, update)
	update_df = DataFrame(time=update.time, event=update.event, count=update.count)
	if !haskey(data_store.station_commuter_count, update.station_id)
		data_store.station_commuter_count[update.station_id] = update_df
		return
	end
	append!(data_store.station_commuter_count[update.station_id], update_df)
end

function update_travel_time!(data_store, update)
	for (k, v) in update.update
		if !haskey(data_store.travel_times, k)
			data_store.travel_times[k] = Dict()
		end
		if !haskey(data_store.travel_times[k], update.target_id)
			data_store.travel_times[k][update.target_id] = []
		end
		append!(data_store.travel_times[k][update.target_id], v)
	end
end

function update_perc_wait_time!(data_store, update)
	for (k, v) in update.update
		if !haskey(data_store.percentage_wait_time, k)
			data_store.percentage_wait_time[k] = Dict()
		end
		if !haskey(data_store.percentage_wait_time[k], update.target_id)
			data_store.percentage_wait_time[k][update.target_id] = []
		end
		append!(data_store.percentage_wait_time[k][update.target_id], v)
	end
end

function update_wait_time!(data_store, update)
	if !haskey(data_store.wait_times, update.station_id)
		data_store.wait_times[update.station_id] = []
	end 

	append!(data_store.wait_times[update.station_id], update.update)
end