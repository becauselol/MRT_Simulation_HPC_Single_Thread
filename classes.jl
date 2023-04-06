struct Event
	time::Float64
	fun::Any # the function to execute
	params::Dict
end

mutable struct Commuter
	origin::String # origin station id
	target::String # path to take
	state::Bool # state of commuter (True means waiting false means moving)
	spawn_time::Float64 # time it was spawned at
	wait_start::Float64 # time it started waiting for the next train
	total_wait_time::Float64 # total time the commuter spent waiting
end

mutable struct Train
	train_id::String
	line::String
	direction::String
	movement::Bool # whether it is moving
	capacity::Int64
	commuters::Dict{String, Vector{Commuter}} # Dictionary, key: station to alight, valu: List of commuters
end

mutable struct Station
	station_id::String
	codes::Vector
	name::String
	stationCodes::Vector{String}
	spawn_rate::Dict{String, Float64}
	time_to_next_spawn::Dict{String, Int64}
	neighbours::Dict{String, Dict{String, Vector}}
	train_transit_time::Int64
	commuters::Dict{String, Vector{Any}} # Dictionary, key: train to board, valu: List of commuters

	function Station(station_id::String, codes::Vector{Any}, name::String, stationCodes::Vector{Any})
		return new(
				station_id,
				codes,
				name,
				stationCodes,
				Dict(),
				Dict(),
				Dict(),
				1,
				Dict()
			)
	end
end

mutable struct Metro
	stations::Dict{Any, Any}
	trains::Dict{Any, Any}
	lines::Dict{Any, Any}
	paths::Dict{Any, Any}
end


mutable struct CommuterGraph
	nodes::Vector{Any}
	edges::Dict{Any, Any}
	dist::Dict{String, Dict{String, Float64}}
	next::Dict{String, Dict{String, Vector}}
	commuter_paths::Dict{String, Dict{String, Vector}}
	function CommuterGraph(nodes::Vector{Any}, edges::Dict{Any, Any})
		return new(
			nodes,
			edges,
			Dict(),
			Dict(),
			Dict()
			)
    end
end



