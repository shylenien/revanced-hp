#!/bin/bash

# Check new patch:
get_date() {
	local auth_header=()
	if [ -n "$GITHUB_TOKEN" ]; then
		auth_header=(-H "Authorization: token $GITHUB_TOKEN")
	fi
	local json
	json=$(curl -s "${auth_header[@]}" "https://api.github.com/repos/$1/releases")
	if [ -z "$json" ]; then
		return
	fi

	local updated_at
	case "$2" in
		latest)
			updated_at=$(echo "$json" | jq -r --arg pat "$3" 'first(.[]? | select(.prerelease == false) | .assets[]? | select(.name | test($pat)) | .updated_at) // empty' 2>/dev/null)
			;;
		prerelease)
			updated_at=$(echo "$json" | jq -r --arg pat "$3" 'first(.[]? | select(.prerelease == true) | .assets[]? | select(.name | test($pat)) | .updated_at) // empty' 2>/dev/null)
			;;
		*)
			updated_at=$(echo "$json" | jq -r --arg tag "$2" --arg pat "$3" 'first(.[]? | select(.tag_name == $tag) | .assets[]? | select(.name | test($pat)) | .updated_at) // empty' 2>/dev/null)
			;;
	esac
	echo "$updated_at"
}

checker(){
	local date1 date2 date1_sec date2_sec repo=$1 ur_repo=$repository check=$3
	date1=$(get_date "$repo" "$2" '\.(jar|rvp|mpp)$')
	date2=$(get_date "$ur_repo" "all" "$check")

	[[ "$date1" == "null" ]] && date1=""
	[[ "$date2" == "null" ]] && date2=""

	if [ -z "$date1" ]; then
		echo -e "\e[31mCould not get date from upstream for $repo\e[0m"
		echo "new_patch=0" >> "$GITHUB_OUTPUT"
		return
	fi

	if [ -z "$date2" ]; then
		echo "new_patch=1" >> "$GITHUB_OUTPUT"
		echo -e "\e[32mNew patch (no existing release in $ur_repo), building...\e[0m"
		return
	fi

	date1_sec=$(date -d "$date1" +%s 2>/dev/null || echo 0)
	date2_sec=$(date -d "$date2" +%s 2>/dev/null || echo 0)

	if [ "$date1_sec" -gt "$date2_sec" ]; then
		echo "new_patch=1" >> "$GITHUB_OUTPUT"
		echo -e "\e[32mNew patch found, building...\e[0m"
	else
		echo "new_patch=0" >> "$GITHUB_OUTPUT"
		echo -e "\e[32mOld patch, not building.\e[0m"
	fi
}
checker $1 $2 $3
