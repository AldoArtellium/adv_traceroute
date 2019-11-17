#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root"
  exit
fi

# Nous initialisons le pool d'adresse, les pools de ports udp et tcp

read -p 'Enter targets list[www.iutbeziers.fr iutrs.unistra.fr rt.iut-velizy.uvsq.fr iut-stmalo.univ-rennes1.fr www.un.org www.iut-blagnac.fr www.ruffat.org]: ' adress_list
if [ -z "$adress_list" ]; then
  adress_list='www.univ-guyane.fr www.iutbeziers.fr iutrs.unistra.fr rt.iut-velizy.uvsq.fr iut-stmalo.univ-rennes1.fr www.un.org www.iut-blagnac.fr www.ruffat.org'
fi

read -p 'Enter udp port list[1149 5060 5004 33434-33436]: ' udp_port
if [ -z "$udp_port" ]; then
  udp_port='1149 5060 5004 33434 33435 33436'
fi

read -p 'Enter tcp port list[21 22 42 80 443]: ' tcp_port
if [ -z "$tcp_port" ]; then
  tcp_port='21 22 42 80 443'
fi


# nous verifions si le dossier temporaire existe deja si il existe nous pouvons soit le suprimer soit le renommer, nous faisont de meme avec le fichier créer pour xdot

if [ -e tmp ]; then
  read -p 'Rename previous temporary folder[Delete]: ' mlk
  
  if [ ! -z "$mlk" ]; then
    cp -r tmp $mlk
  fi
  
  echo '[*] Temporary folder content deleted'
  rm -rf tmp/*
else
  
  echo '[*] Creating new temporary folder'
  mkdir tmp
fi

if [ -e netmap.dot ]; then
  read -p 'Rename previous netmap.dot file[Delete]: ' mlk
  
  if [ ! -z "$mlk" ]; then
    mv netmap.dot $mlk
    echo '[*] netmap.dot renamed'
  else
    rm -rf netmap.dot
    echo '[*] netmap.dot deleted' 
  fi
  

fi

# Nous donons nos trois listes a traceroute_core qui s'occupe de executer les commandes traceroute et les enregitre dans des fichiers

./traceroute_core.sh "$adress_list" "$udp_port" "$tcp_port"

./dot_core.sh "tmp/"

# nous demandons a l'utilisateur s'il veux supprimer le dossier temporaire

echo
read -p 'Remove tmp folder ?[Y/n]: ' response

if [ -z $response ] || [ $response = 'Y' ] || [ $response = 'y' ] || [ $response = 'yes' ]; then
  rm -rf "tmp/"
fi

# s'il veux durectment ouvrir le fichier

read -p 'Xdot the file ?[Y/n]: ' response

if [ -z $response ] || [ $response = 'Y' ] || [ $response = 'y' ] || [ $response = 'yes' ]; then
  xdot netmap.dot
fi