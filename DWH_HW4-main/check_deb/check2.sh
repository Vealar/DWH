rm topics.json
curl http://localhost:8082/v3/clusters/Bqj-ZL7VTU2nFeFTKPsfAw/topics -o topics.json
python3 check_cluster2.py