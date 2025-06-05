import json

with open('topics.json', 'r') as f:
    topics = json.load(f)
print(topics)
for i in topics['data']:
    print(i['topic_name'])