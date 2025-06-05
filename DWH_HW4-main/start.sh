echo "Clearing data"
rm -rf ./data
rm -rf ./data-slave
docker compose down

echo "Starting postgres_master ..."
docker compose up -d  postgres_master
sleep 5

echo "Add user replica,do basebackup, and change configs master and slave"
docker exec -it postgres_master sh /etc/postgresql/bash-scripts/init.sh
echo "Restart postgres_master"
docker compose restart postgres_master
sleep 5

echo "Starting postgres_slave ..."
docker compose up -d  postgres_slave
sleep 5

echo "Starting ZooKeeper..." && docker compose up -d zookeeper && sleep 0
echo "Starting Kafka Broker..." && docker compose up -d broker && sleep 0
echo "Starting Debezium Connector..." && docker compose up -d debezium && sleep 0
echo "Starting Debezium UI..." && docker compose up -d debezium-ui && sleep 0
echo "Starting Kafka REST Proxy..." && docker compose up -d rest-proxy && sleep 0
echo "Starting data_vault ..." && docker compose up -d  data_vault && sleep 0
echo "Starting dmp_service ..." && docker compose up --build -d  dmp_service && sleep 0
echo "Starting Grafana_service" && docker compose up --build -d  grafana && sleep 0
echo "Customization Debezium ..."
[ -f ./debezium/connector.json ] && rm ./debezium/connector.json
python3 ./debezium/conf.py

echo "Kafka Connect ..."
curl -X POST --location "http://localhost:8083/connectors" -H "Content-Type: application/json" -H "Accept: application/json" -d @./debezium/connector.json


echo "Done"
