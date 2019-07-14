# " conbash " alias allowing quick shell access to the first running container 
containerid=$(docker ps | sed -n 2p | cut -d' ' -f1); docker exec -it $containerid /bin/bash;
