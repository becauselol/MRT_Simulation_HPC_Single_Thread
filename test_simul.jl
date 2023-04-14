###
# Create a simple graph and have 1 train 1 line and low spawn rate per line
###
include("import_all.jl")

# io = open("log.txt", "w+")
# logger = SimpleLogger(io)
logger = ConsoleLogger(stderr, Logging.Info)
# fileLogger = SimpleLogger(io, Logging.Debug)
# global_logger(fileLogger)
global_logger(logger)

max_time = 1440
start_time = 345
# station_data = """Station 1,red01
# Station 2,red02/pur02
# Station 3,red03/pur03
# Station 4,pur01
# Station 5,pur04
# Station 6,red04"""

# travel_data = Dict(
# 	"pur" => """pur01,pur02,2
# pur02,pur03,2
# pur03,pur04,2""",
# 	"red" => """red01,red02,2
# red02,red03,2
# red03,red04,2"""
# 	)

# # not being used at the moment
# train_wait_time = """red01,1
# red02,1
# red03,1
# pur01,1
# pur04,1"""

train_period = 2
train_capacity = 1000

# spawn_labels = ["Station 1", "Station 2", "Station 3", "Station 4", "Station 5", "Station 6"]
# spawn_rates = [0 1 1 1 1 1;
# 1 0 1 1 1 1;
# 1 1 0 1 1 1;
# 1 1 1 0 1 1;
# 1 1 1 1 0 1;
# 1 1 1 1 1 0]
@info "$(now()): initialization starting at time "
station_dict = construct_station_dict("data/input/station_data.csv")

station_name_id_map = construct_station_name_id_map(station_dict)

# construct the edges
start_stations = construct_edges_from_edges_dict!(station_dict, ["tel", "ccl", "ewl", "nsl", "nel", "cgl", "dtl"])

lines = construct_lines_from_start_stations(station_dict, start_stations)

commuter_graph = construct_commuter_graph(station_dict)

floyd_warshall!(commuter_graph)

get_all_path_pairs!(commuter_graph)

paths = get_interchange_paths(station_dict, lines, commuter_graph)

trains = Dict()
event_queue = []
for line_code in keys(lines)
	line_duration = get_line_duration(station_dict, lines, line_code)
	depot_id = lines[line_code]["FW"][1]
	result = create_period_train_placement_events(line_code, line_duration, train_period, train_capacity, depot_id, "FW", start_time)

	for (k,v) in result["trains"]
		trains[k] = v 
	end 

	append!(event_queue, result["events"])
end

spawn_events = create_spawn_events!("data/input/spawn_data.csv", station_dict, start_time)

append!(event_queue, spawn_events)

metro = Metro(station_dict, trains, lines, paths);

build_min_heap!(event_queue)

data_store = Data_Store(Dict(), Dict(), Dict(), Dict(), Dict())
@info "$(now()): initialization finish "

@info "$(now()): starting simulation "
final_data = simulate!(max_time, metro, event_queue, data_store)
@info "$(now()): ending simulation "

@info "storing data"
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
