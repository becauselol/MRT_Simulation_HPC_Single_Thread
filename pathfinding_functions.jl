function floyd_warshall!(commuter_graph)
	commuter_graph.dist = Dict()
	commuter_graph.next = Dict()

	for station_id in commuter_graph.nodes 
		commuter_graph.dist[station_id] = Dict()
		commuter_graph.next[station_id] = Dict()

		for id in commuter_graph.nodes 
			commuter_graph.dist[station_id][id] = Inf
			commuter_graph.next[station_id][id] = [-1]
		end 
	end 

	for (i, i_dict) in commuter_graph.edges
		for (j, weight) in i_dict 
			commuter_graph.dist[i][j] = weight
			commuter_graph.next[i][j] = [-1]
		end 
	end 

	for i in commuter_graph.nodes 
		commuter_graph.dist[i][i] = 0
		commuter_graph.next[i][i] = []
	end

	for k in commuter_graph.nodes 
		for i in commuter_graph.nodes 
			for j in commuter_graph.nodes 
				if (commuter_graph.dist[i][k] + commuter_graph.dist[k][j] < commuter_graph.dist[i][j])
					commuter_graph.dist[i][j] = commuter_graph.dist[i][k] + commuter_graph.dist[k][j]
					commuter_graph.next[i][j] = []
					push!(commuter_graph.next[i][j], k)
				elseif commuter_graph.dist[i][k] + commuter_graph.dist[k][j] == commuter_graph.dist[i][j] && k != j && k != i && commuter_graph.dist[i][j] != Inf
					push!(commuter_graph.next[i][j], k)
				end
			end 
		end 
	end 

	@debug "floyd_warshall done"
end

function get_path_to_station!(commuter_graph, i, j)
	all_paths = []

	# if i in keys(commuter_graph.commuter_paths)
	# 	if j in keys(commuter_graph.commuter_paths[i])
	# 		return commuter_graph.commuter_paths[i][j]
	# 	end
	# end

	if (size(commuter_graph.next[i][j])[1] == 0)
		return all_paths
	end

	for k in commuter_graph.next[i][j]
		if k == -1
			push!(all_paths, [i, j])
		else 
			path_i_k = get_path_to_station!(commuter_graph, i, k)
			path_k_j = get_path_to_station!(commuter_graph, k, j)
			for i_k in path_i_k
				for k_j in path_k_j
					temp_i_k = copy(i_k)
					pop!(temp_i_k)
					for el in k_j 
						push!(temp_i_k, el)
					end 

					push!(all_paths, temp_i_k)
				end 
			end 
		end
	end 

	# if !(i in keys(commuter_graph.commuter_paths))
	# 	commuter_graph.commuter_paths[i] = Dict()
	# end 

	# commuter_graph.commuter_paths[i][j] = all_paths

	return all_paths
end

function get_all_path_pairs!(commuter_graph)
	station_ids = commuter_graph.nodes 

	for iId in commuter_graph.nodes 
		if !(iId in keys(commuter_graph.commuter_paths))
			commuter_graph.commuter_paths[iId] = Dict()
		end 

		for jId in commuter_graph.nodes 
			if !(jId in keys(commuter_graph.commuter_paths))
				commuter_graph.commuter_paths[jId] = Dict()
			end 
			if iId == jId
				continue
			end

			commuter_graph.commuter_paths[iId][jId] = get_path_to_station!(commuter_graph, iId, jId)

			if (commuter_graph.commuter_paths[iId][jId] == [])
				continue
			end 

			reverse_path = []
			for path in commuter_graph.commuter_paths[iId][jId]
				push!(reverse_path, reverse(path))
			end 

			commuter_graph.commuter_paths[jId][iId] = reverse_path
		end 
	end 
end 


function get_interchange_paths(station_dict, lines,  commuter_graph)
	if (length(commuter_graph.commuter_paths) == 0)
		floyd_warshall!(commuter_graph)
		get_all_path_pairs!(commuter_graph)
	end 

	paths = Dict()

	for (i_id, station_i) in  station_dict
		paths[i_id] = Dict()

		for (j_id, station_j) in station_dict

			if i_id == j_id
				continue 
			end 

			paths[i_id][j_id] = Dict()

			min_time = Inf
			chosen_lines = []

			for i_code in station_i.codes 
				for j_code in station_j.codes 
					time_taken = commuter_graph.dist["$i_id.$i_code"]["$j_id.$j_code"]

					if time_taken < min_time 
						min_time = time_taken 
						chosen_lines = [(i_code, j_code)]
					elseif time_taken == min_time 
						push!(chosen_lines, (i_code, j_code))
					end 
				end 
			end 

			if min_time == Inf 
				@debug "no path between $i_id and $j_id ?"
			end 

			for (i_code, j_code) in chosen_lines 
				possible_paths = commuter_graph.commuter_paths["$i_id.$i_code"]["$j_id.$j_code"]
				
				for path in possible_paths
					direction = get_direction(lines[i_code]["FW"], i_id, String(split(path[2], ".")[1]))

					board = "$(i_code)_$(direction)"

					alight = nothing 

					for p = 2:size(path)[1]
						prev = path[p-1]
						next = path[p]
						prev_details = String(split(prev, ".")[2])
						next_details = String(split(next, ".")[2])

						if p < size(path)[1] &&  prev_details != next_details
							alight = String(split(prev, ".")[1])
							break
						end 
					end

					if alight == nothing 
						alight = j_id 
					end 

					if !(board in keys(paths[i_id][j_id]))
						paths[i_id][j_id][board] = []
					end 				

					push!(paths[i_id][j_id][board], alight)
				end
			end 

		end 
	end 

	return paths 
end 

