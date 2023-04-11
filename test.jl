using Test
include("classes.jl")
include("station_functions.jl")

s = Station("t", "test", [])
s.neighbours["red"] = Dict()
s.neighbours["red"]["FW"] = ["s", 3]

@testset "Get Neighbour Functions" begin
	@testset "Get ID" begin
		@test get_neighbour_id(s, "red", "FW") == "s"
		@test get_neighbour_id(s, "red", "BW") == nothing
	end;
	@testset "Get Weight" begin
		@test get_neighbour_weight(s, "red", "FW") == 3
		@test get_neighbour_weight(s, "red", "BW") == nothing
	end;
end;