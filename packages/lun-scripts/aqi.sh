#!/bin/bash

exec curl --silent --url \
	'https://api.purpleair.com/v1/sensors/?api_key=14349495-BB81-11EC-B330-42010A800004&location_type=0&max_age=10000&nwlat=48.0298439905454&selat=47.80090276530831&nwlng=-122.49543826162943&selng=-121.84356173837006&fields=pm2.5_30minute' |
	jq '[.data[] | .[1] ] | sort | .[5:-5] | add/length | round / 1'
