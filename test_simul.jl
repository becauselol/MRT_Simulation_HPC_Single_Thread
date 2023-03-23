###
# Create a simple graph and have 1 train 1 line and low spawn rate per line
###

include("functions.jl")
include("classes.jl")
include("heap_functions.jl")

max_time = 10

# Define a few variables
a_neighbour = Dict("l_fw" => ["b", 1])
station_a = Station("a", ["l"], "Station A", 6, 0, a_neighbour, 1, [], [])


b_neighbour = Dict("l_fw" => ["c", 1], "l_bw" => ["a", 1])
station_b = Station("b", ["l"], "Station B", 6, 1, b_neighbour, 1, [], [])

c_neighbour = Dict("l_bw" => ["b", 1])
station_c = Station("c", ["l"], "Station C", 6, 2, c_neighbour, 1, [], [])

train = Train("1", "l", "fw", false, 2, [])


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
		"a_b" => [["b", "l_fw"]],
		"a_c" => [["c", "l_fw"]],
		"b_a" => [["a", "l_bw"]],
		"b_c" => [["c", "l_fw"]],
		"c_a" => [["a", "l_bw"]],
		"c_b" => [["b", "l_bw"]],
	)
metro = Metro(stations, trains, lines, paths)


# Start the Event queue
event_queue = []
first_event = Event(
		0,
		train_reach_station!,
		Dict(
				:time => 0,
				:metro => metro,
				:train => "1",
				:station => "a"
			)
	)


heappush!(event_queue, first_event)

simulate!(max_time, metro, event_queue)