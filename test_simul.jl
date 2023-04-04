###
# Create a simple graph and have 1 train 1 line and low spawn rate per line
###
using Logging
using Plots, DataFrames, StatsPlots

include("simul_functions.jl")
include("construction_functions.jl")
include("classes.jl")
include("heap_functions.jl")
include("hdf5_functions.jl")

# io = open("log.txt", "w+")
# logger = SimpleLogger(io)
logger = ConsoleLogger(stderr, Logging.Info)
# fileLogger = SimpleLogger(io, Logging.Debug)
# global_logger(fileLogger)
global_logger(logger)

max_time = 10000

station_data = """Station 1,red01
Station 2,red02/pur02
Station 3,red03/pur03
Station 4,pur01
Station 5,pur04"""

travel_data = Dict(
	"pur" => """pur01,pur02,2
pur02,pur03,2
pur03,pur04,2""",
	"red" => """red01,red02,2
red02,red03,2"""
	)

# not being used at the moment
train_wait_time = """red01,1
red02,1
red03,1
pur01,1
pur04,1"""

trainPeriod = 1
trainCapacity = 150

spawn_labels = ["Station 1", "Station 2", "Station 3", "Station 4", "Station 5"]
spawn_rates = [0 2 2 2 2;
1 0 1 1 1;
3 3 0 3 3;
1 1 1 0 1;
1 1 1 1 0]

station_dict = construct_station_dict(station_data)

# construct the edges
start_stations = construct_edges_from_edges_dict!(station_dict, travel_data)

lines = construct_lines_from_start_stations(station_dict, start_stations)

train = Train("1", "l", "fw", false, 5, Dict())


trains = Dict(
		"1" => train
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

data_store = Data_Store(Dict(), Dict(), Dict(), Dict(), Dict())

final_data = simulate!(max_time, metro, event_queue, data_store)

store_final_data(final_data, max_time)


# for (k, v) in final_data.wait_times
# 	println("wait times for station $k")
# 	println(v)
# end

# for (origin, v) in final_data.travel_times
# 	for (dest, arr) in v 
# 		println("travel times from station $origin to station $dest")
# 		println(arr)
# 	end 
# end 

# for (k,v) in final_data.station_commuter_count
#     println("Station $k")
#     # display(v)

#     p = @df v plot(:time, [:count], linetype=:steppost, markers=(:circle,2))

#     # @df v annotate!(:time, :count.+0.03, text.(:event, :red, :left,5))
#     savefig(p, save_path*"station_"*k*"_count.png")
# end

# for (k,v) in final_data.station_train_commuter_count
#     println("Station $k")
#     # display(v)

#     p = @df v plot(:time, [:count], linetype=:steppost, markers=(:circle,2))

#     # @df v annotate!(:time, :count.+0.03, text.(:event, :red, :left,5))
#     savefig(p, save_path*"station_train_"*k*"_count.png")
# end
