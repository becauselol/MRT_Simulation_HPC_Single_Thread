struct Event
	time::Int64
	fun::Any # the function to execute
	params::Dict
end

mutable struct Commuter
	origin::String # origin station id
	target::String # path to take
	state::Bool # state of commuter (True means waiting false means moving)
	spawn_time::Int64 # time it was spawned at
	wait_start::Int64 # time it started waiting for the next train
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
	spawn_rate::Int64
	time_to_next_spawn::Int64
	neighbours::Dict{String, Vector}
	train_transit_time::Int64
	commuters::Dict{String, Vector{Commuter}} # Dictionary, key: train to board, valu: List of commuters
	commuter_wait_times::Vector
end

mutable struct Metro
	stations::Dict{String, Station}
	trains::Dict{String, Train}
	lines::Dict{String, Vector}
	paths::Dict{String, Dict{Any, Any}}
end

# mutable struct CommuterNode

# mutable struct CommuterGraph
# 	nodes::Dict{String, CommuterNode}



