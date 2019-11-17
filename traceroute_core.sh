#!/bin/bash


# Créations des fichier traceroute pour le xdot.

# Pour chaque adresse

for adress in $1; do

  # Nous recherchons l'adresse cible qui signifira l'arrivee a la route, s'il est incorect nous n'executons pas le script sur cette adresse
  ipcible=$(dig +short $adress | tail -n 1)
  if [ -z $ipcible ]; then
    echo '[!] '$adress' is Incorect. Enter a correct address, for example www.example.com'
    exit 1
  fi
  echo '[*]' $adress', Target IP:' $ipcible

  # Pour un ttl entre 1 et 30 inclu
  for ttl in $(seq 1 30); do
    echo '[*] Processing TTL' $ttl

    # Tout d'abord le UDP
    # Pour chaque ports udp
    for port in $2; do
      # Nous executons la commande traceroute que nous enregistrons dans une variable
      # -p : spécifie le port, -n : utilise les adresse ip, -A : AS lookup, -q : nombre de paquets envoyer par demande, -f : premier ttl, -m : max ttl, -w : temps d'attente
      # Traceroute renvoie une ligne d'initialisation, nous gardons que le résultat d'ou le tail -n 1
      tr=$(traceroute "$adress" -p $port -n -A -q 1 -N 1 -f $ttl -m $ttl -w 1 | tail -n 1)
      
      # Si nous arrivons a la cible, plus besoin de faire de traceroute sur celuici nous passons a l'adresse suivante
      if [[ "$(echo "$tr" | awk '{print $2}')" = "$ipcible" ]]; then
        # Nous envoyons le resultat dans un fichier
        echo "$tr" | awk '{print $2 " " $3}' >> tmp/$adress
        echo '[*] TTL' $ttl': Arrived in' $adress
        continue 3

      # Si nous trouvons pas d'etoile avant l'AS, pas besoin de faire d'autre traceroute sur le même ttl nous incrementons donc celui-ci
      elif [ ! "$(echo "$tr" | cut -d'[' -f1 | grep "*")" ]; then
        echo "$tr" | awk '{print $2 " " $3}' >> tmp/$adress
        continue 2
      fi
    done

    # Puis pareil pour l'ICMP
    # -I : ICMP, pas besoin de spécifier de ports en ICMP
    tr=$(traceroute "$adress" -I -n -A -q 1 -N 1 -f $ttl -m $ttl -w 1 | tail -n 1)

    if [[ "$(echo "$tr" | awk '{print $2}')" = "$ipcible" ]]; then
      echo "$tr" | awk '{print $2 " " $3}' >> tmp/$adress
      echo '[*] TTL' $ttl': Arrived in' $adress
      continue 2
    elif [ ! "$(echo "$tr" | cut -d'[' -f1 | grep "*")" ]; then
      echo "$tr" | awk '{print $2 " " $3}' >> tmp/$adress
      continue
    fi

    # Et enfin pareil pour le TCP
    for port in $3; do
      # -T : TCP
      tr=$(traceroute "$adress" -T -p $port -n -A -q 1 -N 1 -f $ttl -m $ttl -w 1 | tail -n 1)

      if [[ "$(echo "$tr" | awk '{print $2}')" = "$ipcible" ]]; then
        echo '[*] TTL' $ttl': Arrived in' $adress
        echo "$tr" | awk '{print $2 " " $3}' >> tmp/$adress
        continue 3
      elif [ ! "$(echo "$tr" | cut -d'[' -f1 | grep "*")" ]; then
        echo "$tr" | awk '{print $2 " " $3}' >> tmp/$adress
        continue 2
      fi
    done
    # Si après tout les essais nous avons encore une etoile, alors nous la laissons aller dans le fichier car nous estimons avoir tout essayer
    echo '[*] TTL' $ttl': Found "*" after all try at' $adress
    echo "$tr" | awk '{print $2}' >> tmp/$adress
  done
done

