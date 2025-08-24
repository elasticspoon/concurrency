# echo "Benchmarking 1 Concurrent Request (1000 Total)"
# ab -n 10000 -c 1 http://localhost:3000/
# echo "Benchmarking 10 Concurrent Requests (1000 Total)"
# ab -n 10000 -c 10 http://localhost:3000/
# echo "Benchmarking 100 Concurrent Requests (1000 Total)"
# ab -n 10000 -c 100 http://localhost:3000/

# echo "Benchmarking 1 Concurrent Request (1000 Total)"
# ab -n 10 -c 1 http://localhost:3000/sleep
# echo "Benchmarking 10 Concurrent Requests (1000 Total)"
# ab -n 10 -c 5 http://localhost:3000/sleep
echo "Benchmarking 100 Concurrent Requests (1000 Total)"
ab -n 10 -c 10 http://localhost:3000/sleep
#
# echo "Benchmarking 1 Concurrent Request (1000 Total)"
# ab -n 10 -c 1 http://localhost:3000/sleep
# echo "Benchmarking 10 Concurrent Requests (1000 Total)"
# ab -n 10 -c 5 http://localhost:3000/sleep
# echo "Benchmarking 100 Concurrent Requests (1000 Total)"
# ab -n 10 -c 10 http://localhost:3000/sleep
