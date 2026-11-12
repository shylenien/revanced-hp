#!/bin/bash

# Check github connection stable or not:
check_connection() {
	local auth_header=()
	if [ -n "$GITHUB_TOKEN" ]; then
		auth_header=(-H "Authorization: token $GITHUB_TOKEN")
	fi
	local status_code
	status_code=$(curl -s -o /dev/null -w "%{http_code}" "${auth_header[@]}" "https://api.github.com/zen")
	if [ "$status_code" = "200" ]; then
		echo "internet_error=0" >> $GITHUB_OUTPUT
		echo -e "\e[32mGithub connection OK\e[0m"
	else
		echo "internet_error=1" >> $GITHUB_OUTPUT
		echo -e "\e[31mGithub connection not stable! (HTTP $status_code)\e[0m"
	fi
}
check_connection
