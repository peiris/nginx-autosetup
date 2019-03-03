#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
	echo -e "Sorry, you need to run this as root"
	exit 1
fi

echo -e "Please enter your vhost name: "
read vhost_name
echo "Nice to meet you $vhost_name"