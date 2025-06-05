import json

with open('clusters.json', 'r') as f:
    clusters = json.load(f)
print(clusters)