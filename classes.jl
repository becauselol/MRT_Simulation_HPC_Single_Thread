struct Event
	time::Int64
	fun::Any # the function to execute
	params::Dict
end


mutable struct Commuter
	origin::Int64 # origin station id
	path::Vector{Vector} # path to take
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
	commuters::Vector{Commuter}
end

mutable struct Station
	station_id::String
	codes::Vector
	name::String
	spawn_rate::Float64
	time_to_next_spawn::Int64
	neighbours::Dict{String, Vector}
	train_transit_time::Int64
	commuters::Vector{Commuter}
	commuter_wait_times::Vector
end

mutable struct Metro
	stations::Dict{String, Station}
	trains::Dict{String, Train}
	lines::Dict{String, Vector}
	paths::Dict{String, Vector}
end

