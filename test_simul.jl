###
# Create a simple graph and have 1 train 1 line and low spawn rate per line
###
using Logging

include("simul_functions.jl")
include("classes.jl")
include("heap_functions.jl")

# io = open("log.txt", "w+")
# logger = SimpleLogger(io)
logger = ConsoleLogger(stderr, Logging.Debug)
# fileLogger = SimpleLogger(io, Logging.Debug)
# global_logger(fileLogger)
global_logger(logger)

max_time = 10

# Define a few variables
a_neighbour = Dict("l_fw" => ["b", 1])
station_a = Station("a", ["l"], "Station A", 6, 0, a_neighbour, 2, Dict(), [])


b_neighbour = Dict("l_fw" => ["c", 2], "l_bw" => ["a", 1])
station_b = Station("b", ["l"], "Station B", 6, 1, b_neighbour, 2, Dict(), [])

c_neighbour = Dict("l_bw" => ["b", 2])
station_c = Station("c", ["l"], "Station C", 6, 2, c_neighbour, 2, Dict(), [])

train = Train("1", "l", "fw", false, 5, Dict())


stations = Dict(
		"a" => station_a,
		"b" => station_b,
		"c" => station_c
	)

trains = Dict(
		"1" => train
	)

lines = Dict(
		"l_fw" => ["a", "b", "c"],
		"l_bw" => ["c", "b", "a"]
	)

paths = Dict(
		"a" => Dict(
			"b" => Dict(
				"board" => "l_fw",
				"alight" => "b"),
			"c" => Dict(
				"board" => "l_fw",
				"alight" => "c")
			),
		"b" => Dict(
			"a" => Dict(
				"board" => "l_bw",
				"alight" => "a"),
			"c" => Dict(
				"board" => "l_fw",
				"alight" => "c")
			),
		"c" => Dict(
			"a" => Dict(
				"board" => "l_bw",
				"alight" => "a"),
			"b" => Dict(
				"board" => "l_bw",
				"alight" => "b")
			)
	)
metro = Metro(stations, trains, lines, paths)


# Start the Event queue
event_queue = []
first_event = Event(
		0,
		train_reach_station!,
		Dict(
				:time => 0,
				:train => "1",
				:station => "a"
			)
	)

spawn_event_a = Event(
		0,
		spawn_commuter!,
		Dict(
				:time => 0,
				:station => "a"
			)

	)

spawn_event_b = Event(
		1,
		spawn_commuter!,
		Dict(
				:time => 1,
				:station => "b"
			)

	)

spawn_event_c = Event(
		2,
		spawn_commuter!,
		Dict(
				:time => 2,
				:station => "c"
			)

	)
heappush!(event_queue, first_event)
heappush!(event_queue, spawn_event_a)
heappush!(event_queue, spawn_event_b)
heappush!(event_queue, spawn_event_c)

data_store = Data_Store(Dict(), Dict(), Dict(), Dict())

final_data = simulate!(max_time, metro, event_queue, data_store)

for (k, v) in final_data.wait_times
	println("wait times for station $k")
	println(v)
end

for (origin, v) in final_data.travel_times
	for (dest, arr) in v 
		println("travel times from station $origin to station $dest")
		println(arr)
	end 
end 

for (k, v) in final_data.station_commuter_count
	println("commuter count for station $k")
	new = []
	for count in v
		push!(new, count.count)
	end
	println(new)
end

for (k, v) in final_data.station_train_commuter_count
	println("commuter count for trains at station $k")
	new = []
	for count in v
		push!(new, count.count)
	end
	println(new)
end

# close(io)
