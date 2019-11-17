#!/bin/bash

# Creation du xdot

# Nous fonctionons en decale, ex:
# avant la boucle while nous écrivons la premiere ligne (gateway) 
# Dans la boucle:
# il faut ensuite mettre un lien (-> ou alors --) puis la deuxieme adresse avec les modifications de la ligne 
# Nous retournons a la lige pour réecrire la même adresse pour ainsi créer une route.

# Pour chaque etoile nous creons une nouvelle variable pour ainsi eviter que xdot les rassemblent en un point et fausse le résultat

# ligne de declaration de graph, ainsi qu'une node, elle sert a appliquer une option sur tout le graph 

if [ "$1" == "" ]; then
  echo "enter a folder to enter in"
  exit
fi

echo 'digraph file { node[shape=box];' > "netmap.dot"
id=0
for address in $(find $1 -type f); do

  # Ajout de l'addresse suivante et precedente pour chaque ligne de fichier route

  cat $address | grep -qv ';' && cat $address | awk '{print $0 " ; "}' | tac | awk '{print $0 " " last}{last=$1}' | tac | awk '{print $0 " " last}{last=$1}' > $address.tmp
  mv $address.tmp $address


  #cat $address

  echo '[*] Processing' $address.rte

  # Couleur random avec un interval de 200
  color=$(( ( RANDOM % 16777215 ) * 200 + 1 ))

  echo ' ' >> "netmap.dot"

  # Crée une copie du fichier route
  cp "$address" "$address.tmp"

  # Print la gateway * ; * *
  awk 'NR==1{printf $1 "\\n"; if($2 != ";"){printf $2}} BEGIN{printf "\""} END{printf "\""}' "$address.tmp" >> "netmap.dot"
  # Suprime la ligne de la gateway dans le fichier temporaire
  tail -n +2 "$address.tmp" > "$address.tmp2" && mv "$address.tmp2" "$address.tmp"

  # Lit ligne par ligne $address.tmp ici d
  while read line; do
    # ip2 et as2 corespondent à l'historique, il s'agit 
    ip2=$(echo -n "$line" | awk '{printf $1}')
    as2=$(echo -n "$line" | awk '{if($2 != ";"){printf $2}else{printf "*"}}' | cut -c2-)
    as2=${as2%?}
    echo 'address:' $address 'ip2:' $ip2 'as2:' $as2
    
    if [ "$(echo $as2 | grep '*' )" ]; then as2='*'; fi

    # Si il y a une etoile dans la ligne actuelle
    if [ "$(echo "$line" | cut -d";" -f1 | cut -d"[" -f 1 | grep "*")" ]; then
      # On recupere ce qui a deja ete marque
      a=$(tail -n 1 "netmap.dot")
      # s'il s'agit deja d'une variable
      if [ "$(echo $a | grep 'star' )" ];then 
        ip1="$(echo $a | cut -d' ' -f1)"
        as1='*'
      else
        ip1=$(echo -n "$a" | cut -d'\' -f1 | cut -c2-)
        as1=$(echo -n "$a" | cut -d'\' -f2 | cut -c3-)
        as1=${as1%??}
      fi
      
      echo 'address:' $address 'ip1:' $ip1 'as1:' $as1

      # Puis on le supprime
      head -n -1 "netmap.dot" > "netmap.dot.tmp" && mv "netmap.dot.tmp" "netmap.dot"

      # On cree une variable avec comme label * * * et comme AS *
      echo star_$id '[label="* * *\n[*]"];' >> "netmap.dot"
      echo '"network_'"$ip1"_"$as1"_"star_$id"_"*"'" [label="'"$ip1" "$as1\n" '->' "\nstar_$id" "*"'" shape=ellipse];' >> "netmap.dot"

      # On remet la ligne precedament en direction de la variable
      echo -n "$a" '-> "network_'"$ip1"_"$as1"_"star_$id"_"*"'" ->' "star_$id" >> "netmap.dot"
      # Les options de direction de la fleche, la couleur, l epesseur du trait
      echo "[penwidth=2 color=\"$(printf "#%06X" $color)\"];" >> "netmap.dot"
      echo -n "star_$id" >> "netmap.dot"
      id=$((id +1))
    else  
      a=$(tail -n 1 "netmap.dot")
      if [ "$(echo $a | grep 'star' )" ];then 
        ip1="$(echo $a | cut -d' ' -f1)"
        as1='*'
      else
        ip1=$(echo -n "$a" | cut -d'\' -f1 | cut -c2-)
        as1=$(echo -n "$a" | cut -d'\' -f2 | cut -c3-)
        as1=${as1%??}
      fi
      if [ "$(echo $as1 | grep '*' )" ]; then as1='\*'; fi
      
      
      # Sinon nous ajoutons unt fleche
      echo -n ' -> "network_'"$ip1"_"$as1"_"$ip2"_"$as2"'" -> ' >> "netmap.dot"
      # Nous recuperons le deuxieme et le troisieme argument de la ligne et les metons entre guillemet
      echo -n "$line" | awk '{printf $1 "\\n"; if($2 != ";"){printf $2}} BEGIN{printf "\""} END{printf "\""}' >> "netmap.dot"
      # Options de la ligne puis retour a la ligne
      echo " [penwidth=2 color=\"$(printf "#%06X" $color)\"];" >> "netmap.dot"

      echo '"network_'"$ip1"_"$as1"_"$ip2"_"$as2"'" [label="'"$ip1" "$as1\n" '->' "\n$ip2" "$as2"'" shape=ellipse];' >> "netmap.dot"

      # nosu reprintons le deuxieme et le troisieme argument
      echo -n "$line" | awk '{printf $1 "\\n"; if($2 != ";"){printf $2}} BEGIN{printf "\""} END{printf "\""}' >> "netmap.dot"
    fi

  done < $address.tmp
  
  # On retire la derniere ligne qui est en trop
  head -n -1 "netmap.dot" > "netmap.dot.tmp" && mv "netmap.dot.tmp" "netmap.dot"

  # On rm le fichier temporaire du fichier temporaire
  rm -f $address.tmp

done

# Fin du graph
echo '}' >> "netmap.dot"

#On execute le scipt en root il crée donc tout en root, nous le chmodons
chown "$USER:users" netmap.dot

echo "[*] Dot file created"
