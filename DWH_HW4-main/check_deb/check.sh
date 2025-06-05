rm clusters.json
curl http://localhost:8082/v3/clusters -o clusters.json
python3 check_cluster.py
#Bqj-ZL7VTU2nFeFTKPsfAw
