from collections import defaultdict
import heapq

n, m = map(int, input().split())

graph = [[] for i in range(n+1)]
indgre = [0 for i in range(n+1)]  
for _ in range(m):  
    a, b = map(int, input().split())
    graph[a].append(b)
    indgre[b] += 1
    
heap = []
for i in range(1, n+1):  
    if indgre[i] == 0:
        heapq.heappush(heap, i)

ans = []
while heap:
    curr = heapq.heappop(heap)
    ans.append(curr)
    for i in graph[curr]:
        indgre[i] -= 1
        if indgre[i] == 0:
            heapq.heappush(heap, i)

if len(ans) == n:
    print(*ans)
else:
    print(-1)