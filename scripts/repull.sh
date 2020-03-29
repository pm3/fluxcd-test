#!/bin/bash
UNAME="astonunion"
UPASS="BSDb1M1Jor9VsAXprqd8phySF/byYa8h"
HOST="astonunion.azurecr.io"
JSONPATH="{range .items[*]}{.metadata.name}{'\t'}{.status.phase}{'\t'}{.status.containerStatuses[*].image}{'\t'}{.status.containerStatuses[*].imageID}{'\n'}{end}"

microk8s.kubectl get pods -o=jsonpath="$JSONPATH" | grep $HOST | grep Running > out.txt

while read name status image image_digest; do
 local_digest=$(echo -n ${image_digest} | grep -oE '[^:]+$' )
 #create path for external regitry
 path=$(echo $image | sed 's|^\(.*\)/\(.*\):\(.*\)$|/v2/\2/manifests/\3|')
 #call external registry and extract header Docker-Content-Digest
 digest_header=$(curl -s -I -u $UNAME:$UPASS -H "Accept: application/vnd.docker.distribution.manifest.v2+json" https://$HOST$path | grep Docker-Content-Digest)
 ext_digest=$(echo -n ${digest_header} | tr -d '\r\n' | grep -oE '[^:]+$' )
 if [ "$local_digest" = "$ext_digest" ]; then
  echo "pod $name equals digest $local_digest"
 else
  echo "pod $name not equals digest '$local_digest' != '$ext_digest'"
  microk8s.kubectl delete pod $name
 fi 
done < out.txt