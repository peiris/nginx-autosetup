#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
	echo -e "Sorry, you need to run this as root"
	exit 1
fi

echo -e "Please enter your name: "
read name
echo "Nice to meet you $name"