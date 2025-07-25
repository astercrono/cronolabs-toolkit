#!/usr/bin/env bash
wget -P komodo https://raw.githubusercontent.com/moghtech/komodo/main/compose/mongo.compose.yaml &&
	wget -P komodo https://raw.githubusercontent.com/moghtech/komodo/main/compose/compose.env

# THese are files that I should pull down separately, modify, and add to this repository
# TODO: Figure out how to handle secrets?
