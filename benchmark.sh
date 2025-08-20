echo "Benchmarking 1 Concurrent Request (1000 Total)"
ab -n 1000 -c 10 http://localhost:3000/
echo "Benchmarking 10 Concurrent Requests (1000 Total)"
ab -n 1000 -c 1 http://localhost:3000/
