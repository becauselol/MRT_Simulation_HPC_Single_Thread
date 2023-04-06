function heap_left(i)
	return 2i
end

function heap_right(i)
	return 2i + 1
end

function heap_parent(i)
	return convert(Int32, floor(i/2))
end

function heappush!(heap, event)
	push!(heap, event)
	index = size(heap)[1]
	while index > 1 && heap[heap_parent(index)].time > heap[index].time

		temp = heap[heap_parent(index)]
		heap[heap_parent(index)] = heap[index]
		heap[index] = temp

		index = heap_parent(index)
	end
end

function min_heapify!(heap, index)
	left = heap_left(index)
	right = heap_right(index)
	if left <= size(heap)[1] && heap[left].time < heap[index].time
		smallest = left 
	else
		smallest = index
	end

	if right <= size(heap)[1] && heap[right].time < heap[smallest].time
		smallest = right 
	end
	
	if smallest != index
		temp = heap[smallest]
		heap[smallest] = heap[index]
		heap[index] = temp

		min_heapify!(heap, smallest)
	end
end

function heappop!(heap)
	min_event = heap[1]
	heap[1] = heap[size(heap)[1]]
	pop!(heap)

	min_heapify!(heap, 1)

	return min_event
end

function build_min_heap!(heap)
	start_idx = trunc(Int, size(heap)[1]/2) + 1

	for i = start_idx : -1 : 1
		min_heapify!(heap, i)
	end 
end 