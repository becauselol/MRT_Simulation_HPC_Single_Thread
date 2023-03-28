struct Station_Commuter_Count
	station_id::String 
	time::Int64
	event::String
	count::Int64
end

struct Train_Commuter_Count
	station_id::String 
	time::Int64
	event::String
	count::Int64
end

struct Wait_Time_Update
	station_id::String
	update::Vector{Int64}
end

struct Travel_Time_Update
	target_id::String
	update::Dict{String, Vector{Int64}} # key is origin_id, value is the travel time
end

mutable struct Data_Store
	wait_times::Dict{String, Vector{Int64}}
	travel_times::Dict{String, Dict{String, Vector{Int64}}}
	station_commuter_count::Dict{String, Vector{Station_Commuter_Count}}
	station_train_commuter_count::Dict{String, Vector{Train_Commuter_Count}}
end

function update_train_count!(data_store, update)
	if !haskey(data_store.station_train_commuter_count, update.station_id)
		data_store.station_train_commuter_count[update.station_id] = []
	end
	push!(data_store.station_train_commuter_count[update.station_id], update)
end

function update_station_count!(data_store, update)
	if !haskey(data_store.station_commuter_count, update.station_id)
		data_store.station_commuter_count[update.station_id] = []
	end
	push!(data_store.station_commuter_count[update.station_id], update)
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

function update_wait_time!(data_store, update)
	if !haskey(data_store.wait_times, update.station_id)
		data_store.wait_times[update.station_id] = []
	end 

	append!(data_store.wait_times[update.station_id], update.update)
end