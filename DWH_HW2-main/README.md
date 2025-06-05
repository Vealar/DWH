# dhw_hw_1
Сначала я поднял образ postgres затем написал инициализацию бд, но по сути в 3 задании мы также в мастере и слэйве поднимаем образ, и делаем инициализацию. И в целом в критериях оценки оценивается репликация, поэтому я прикрепил уже итоговую версию, где я поднимаю реплику в docker compose и настраиваю репликацию.  
Для того чтобы поднять реплику необходимо:
1. Установить и запустить docker
2. Наличие интепретатора командной строки чтобы запускать .sh файлы
3. Запустить start.sh, перейдя в директорию hw_1 (например так bash start.sh)  
Теперь давайте я опишу собственно код:
Сам docker-compose ,будет запускать 2 контейнера postgres_master и postgres_slave.
Postgres_master:  
1) Берем образ последней версии постгре image: postgres:latest и называем соответсвующе контейнер: container_name: postgres_master
2) Внутри контейнера он будет работать на порте 5432 а на хосте отображаться на порт 5433 ports: - "127.0.0.1:5433:5432"
3) Базовые данные для входа environment:  - POSTGRES_USER=postgres - POSTGRES_PASSWORD=postgres
4) Теперь самое интересное volumes :  
   4.1)  - ./data:/var/lib/postgresql/data  
         - ./data-slave:/var/lib/postgresql/data-slave  
   в дату мы маунтим данные с бд мастера а в data slave в будущем будут данные для slave   
   4.2) - ./data_init:/data_init  
        - ./create.sql:/docker-entrypoint-initdb.d/create.sql  
        - ./init.sql:/docker-entrypoint-initdb.d/init.sql  
      create.sql инициализирует саму структуру бд а init.sql заполняет тестовыми данными, которые я сгенерировал чтобы проверить скрипт и репликацию.
   Собственно папка data_init содержит в себе csv файлы для заполнения  
   4.3) - ./init-script:/etc/postgresql/init-script
         Здесь мы закинули конфиги на контейнер чтобы потом скриптом bash поменять их у мастера и слэйва  
   4.4) - ./bash-scripts:/etc/postgresql/bash-scripts
         Баш скрипты понятно будет дальше зачем я их закинул  
   Postgres slave: все настройки как у мастера только на хосте она будет запускаться на 5434 и вместо всех volumes master мы оставляем один чтобы она запустилась на бэкапе основной бд из папки data-slave  
Теперь разберем файл запуска start.sh  
   1) Сначала мы очищаем данные если они остались после предыдущего запуска, а именно:  
      echo "Clearing data"  
      rm -rf ./data  
      rm -rf ./data-slave  
      docker-compose down
   2) Затем запускаем самого postgres_master, подключаемся к его контейнеру и запускаем скрипт init.sh который предварительно был закинут в volume.  
      docker-compose up -d  postgres_master  
      docker exec -it postgres_master sh /etc/postgresql/bash-scripts/init.sh
      init.sh:  
      #!/bin/bash  
      set -e  

      sh /etc/postgresql/bash-scripts/add_user.sh  
      sh /etc/postgresql/bash-scripts/basebackup.sh  
      sh /etc/postgresql/bash-scripts/change_configs.sh
      Все эти скрипты уже на контейнере, первый добавляет пользователя для подключения реплики, второй создает backup в папку data-slave с которой запустится postgres_slave и            третий настраивает конфиги, если первые два почти не изменились с семинара, то настройку конфига разберем по подробнее:
      change_configs.sh  
      #!/bin/bash   
      set -e  
      cp /etc/postgresql/init-script/config/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf  
      cp /etc/postgresql/init-script/config/postgresql.conf /var/lib/postgresql/data/postgresql.conf  
      cp /etc/postgresql/init-script/config/postgresql.conf /var/lib/postgresql/data-slave/postgresql.conf  
      cp /etc/postgresql/init-script/slave-config/postgresql.auto.conf /var/lib/postgresql/data-slave/postgresql.auto.conf  
      В pg_hba ключевая строка host    replication     replicator      0.0.0.0/0               trust для возможности подключиться реплике, собственно этот конфиг мы меняем у мастера. postgresql.conf настраивает репликацию, соответственно мы меняем этот конфиг и у мастера и у слэйва. И чтобы слэйв понял куда надо подключаться и откуда реплицировать данные мы меняем для него конфиг postgresql.auto.conf  
      То есть мы поняли настройку мастера, после чего в нашем start.sh мы перезапускаем мастера и подключаем реплику, ну и все в целом мы настроили репликацию.  
      Для +1 балла я написал скрипт в нем 3 CTE : flight info считает по каждому перелету сколько было там человек а dep_info и arr_info уже группируют по аэропортам и получают для  каждого аэропорта сколько раз из него вылетали и прилетали и суммарное число на вылетах и прилетах соответсвенно, в конце мы просто объединяем эти 2 таблицы и получаемый то, что хотели.  
      Не то чтобы я использовал код из открытых источников, но в целом я опирался на гит с семинарами и чтобы закрыть пробелы в понимании всего посмотрел несколько видео:  
      https://www.youtube.com/watch?v=FC2JMBYDcJE&t=515s  
      https://www.youtube.com/watch?v=p2PH_YPCsis&list=LL&index=2  
      https://www.youtube.com/watch?v=SXwC9fSwct8&list=LL&index=3&t=1088s  
      https://www.youtube.com/watch?v=pg19Z8LL06w&list=LL&index=4
# dhw_hw_2
В качестве архитектуры была выбрана Data Vault 1.0 с элементами 2.0. Якорная архитектура была бы полезнее для сильно изменяющихся данных, а у наших сущностей в целом определенная стрктура. Также полностью переходить на 2.0 не стали, из-за сложности внедрения и избыточности для задачи. Элементы 2.0, которые мы затронули это представление суррогатных ключей в виде хэшэй бизнес ключей + использование Kafka.  
Мы написали DDL для детального слоя, который находится в ddl_dwh.sql.  
ER диаграмма находится в DDL.png.  
В итоге после определения архитектуры мы поднимаем контейнер postgres, где будет находиться детальный слой - container_name: data_vault.  
Следующий шаг - поднятие кафки: для чего используя семинарские скрипты мы поднимаем контейнеры zookeeper, broker, debezium, debezium-ui, rest-proxy.  
Все контейнеры поднимаются в одном docker compose, и для настройки мы используем дефолтные для сервисов порты + healthcheck для проверки состояния сервисов.  
Рассмотрим в целом запуск приложения - для чего необходимо запустить также скрипт start.sh(например командой sh start.sh).   
Поднятие мастера и реплики остается аналогичным, изменения начинаются с поднятия контейнеров для kafka:  
echo "Starting ZooKeeper..." && docker compose up -d zookeeper && sleep 0  
echo "Starting Kafka Broker..." && docker compose up -d broker && sleep 0  
echo "Starting Debezium Connector..." && docker compose up -d debezium && sleep 0  
echo "Starting Debezium UI..." && docker compose up -d debezium-ui && sleep 0  
echo "Starting Kafka REST Proxy..." && docker compose up -d rest-proxy && sleep 0    
И затем мы поднимаем детальный слой:    
echo "Starting data_vault ..." && docker compose up -d  data_vault && sleep 0    
В окончании поднимаем dmp service:    
echo "Starting dmp_service ..." && docker compose up --build -d  dmp_service && sleep 0    
DMP_service рассмотрим позже, а сейчас затроним следующие строки start.sh:    
echo "Customization Debezium ..."    
[ -f ./debezium/connector.json ] && rm ./debezium/connector.json    
python3 ./debezium/conf.py - для настройки debezium мы запускаем conf.py и получаем конфиг в json формате в connector.json    
последним действием подключаемся со сгенерированным конфигом - echo "Kafka Connect ..."    
curl -X POST --location "http://localhost:8083/connectors" -H "Content-Type: application/json" -H "Accept: application/json" -d @./debezium/connector.json.    
Таким образом мы подняли детальный слой dwh в контейнере docker настроили передачу данных с помощью kafka(папка check_deb взята из семинара для проверки работоспособности kafka) и
c помощью dmp сервиса читаем данные из kafka и записываем в data_vault.    
DMP сервис также поднят в виде контейнера docker и билдится используя dockerfile:     
в котором за базовый image мы берем python затем командной RUN apt-get update && apt-get install -y libpq-dev gcc && rm -rf /var/lib/apt/lists/*   
устанваливаем системные пакеты внутри контейнера и внутри контейнера будет запускаться основной python файл при инициализации.     
Устройство dmp.py:    
Data manage platform представляет из себя класс DmpService, при инициализации мы заполняем kafka_config для consumer, pg_config для подключения к postgres и topic_mapping - который соотносит бд из мастера к методам обрабатывающим сообщения кафки. topic_processing_order задает очередь обработки топиков для потоков. DMP реализован как один универсальный класс, читающий сообщения кафки(+ 4 балла). Далее есть вспомогательные методы для лучшего устройства кода      
Получение текущего времени    
def get_current_timestamp(self):    
Генерация хэша для суррогатных ключей     
def generate_md5_hash(self, *args):   
Создание консумеров    
def create_consumer(self, topic):    
Подключение к бд    
def create_db_connection(self):     
Для каждой топик есть метод, который обрабатывает данные из соответсвующих таблиц вида def process_*   
process_topic - общий метод который получает информацию и перенаправляет в соответсвующую функцию   
run - запускает параллельные потоки для обработки сообщений kafka в нужном порядке
Для построения dwh использовали семинары + :
https://www.youtube.com/watch?v=-ZgzpQXsxi0&t=1780s   
https://www.youtube.com/watch?v=IZw1cB1uDts&t=2518s   
https://habr.com/ru/articles/850280/  
https://www.astera.com/ru/type/blog/data-vault-2/  
https://www.scalefree.com/consulting/data-vault-2-0/  
Для kafka - семинары   
Для dmp:   
https://docs.bitquery.io/docs/streams/kafka-streams-python-thread/  
https://stackoverflow.com/questions/50807514/kafka-python-consumers-running-in-parallel-threads     
https://aayush-srivastava.hashnode.dev/optimizing-kafka-consumer-by-multi-threading-in-python  
https://www.restack.io/p/building-ai-applications-with-kafka-answer-python-confluent-kafka-consumer-multiprocessing-cat-ai   
