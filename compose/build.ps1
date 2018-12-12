docker network create --driver bridge back-end
docker volume create  --driver local --name=pgvolume
docker volume create  --driver local --name=pga4volume
docker-compose -f "docker-compose-services\docker-compose.yaml" up -d --build