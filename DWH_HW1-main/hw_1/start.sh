echo "Clearing data"
rm -rf ./data
rm -rf ./data-slave
docker-compose down

echo "Starting postgres_master ..."
docker-compose up -d  postgres_master
sleep 30

echo "Add user replica,do basebackup, and change configs master and slave"
docker exec -it postgres_master sh /etc/postgresql/bash-scripts/init.sh
echo "Restart postgres_master"
docker-compose restart postgres_master
sleep 20

echo "Starting postgres_slave ..."
docker-compose up -d  postgres_slave
sleep 5

echo "Done"
