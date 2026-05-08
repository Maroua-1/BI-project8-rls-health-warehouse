content = """services:

  postgres:
    image: postgres:15-alpine
    container_name: hopital_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: hopital_maroc
      POSTGRES_USER: hopital_admin
      POSTGRES_PASSWORD: HopitalMaroc2024!
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/migrations:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U hopital_admin -d hopital_maroc"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - hopital_net

  keycloak_db:
    image: postgres:15-alpine
    container_name: hopital_keycloak_db
    restart: unless-stopped
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: keycloak_secret_2024
    volumes:
      - keycloak_db_data:/var/lib/postgresql/data
    networks:
      - hopital_net

  keycloak:
    image: quay.io/keycloak/keycloak:23.0
    container_name: hopital_keycloak
    restart: unless-stopped
    command: start-dev
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://keycloak_db/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: keycloak_secret_2024
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: Admin@2024
      KC_HOSTNAME_STRICT: "false"
      KC_HTTP_ENABLED: "true"
    ports:
      - "8080:8080"
    depends_on:
      - keycloak_db
    networks:
      - hopital_net

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: hopital_backend
    restart: unless-stopped
    environment:
      DATABASE_URL: postgresql://hopital_admin:HopitalMaroc2024!@postgres:5432/hopital_maroc
      REDIS_URL: redis://redis:6379
      ELASTICSEARCH_URL: http://elasticsearch:9200
      KEYCLOAK_URL: http://keycloak:8080
      KEYCLOAK_REALM: hopital-maroc
      KEYCLOAK_CLIENT_ID: hopital-app
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - hopital_net

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: hopital_frontend
    restart: unless-stopped
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:8000
      NEXT_PUBLIC_KEYCLOAK_URL: http://localhost:8080
      NEXT_PUBLIC_KEYCLOAK_REALM: hopital-maroc
      NEXT_PUBLIC_KEYCLOAK_CLIENT_ID: hopital-app
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - hopital_net

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: hopital_elasticsearch
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - hopital_net

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: hopital_kibana
    restart: unless-stopped
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
    networks:
      - hopital_net

  superset:
    image: apache/superset:3.0.0
    container_name: hopital_superset
    restart: unless-stopped
    environment:
      SUPERSET_SECRET_KEY: superset_secret_hopital_2024
    ports:
      - "8088:8088"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - hopital_net

  redis:
    image: redis:7-alpine
    container_name: hopital_redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    networks:
      - hopital_net

  grafana:
    image: grafana/grafana:10.2.0
    container_name: hopital_grafana
    restart: unless-stopped
    environment:
      GF_SECURITY_ADMIN_PASSWORD: grafana2024
    ports:
      - "3001:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - hopital_net

volumes:
  postgres_data:
  keycloak_db_data:
  elasticsearch_data:
  grafana_data:

networks:
  hopital_net:
    driver: bridge
"""

with open('docker-compose.yml', 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)
print('docker-compose.yml recree avec succes !')