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