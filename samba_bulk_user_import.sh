#!/bin/bash

# Bulk User Creation Script for Samba AD-DC
# Author: fire310w
# Date: 14/03/2025

# Variables
CSV_FILE="users.csv"
DOMAIN=""
SERVER_NAME=""
DEFAULT_PASSWORD="P@ssw0rd"
PRI_GROUP="Domain Users"
PRI_GROUP_ID='1006'
LOGIN_SHELL="/bin/bash"
UNIX_HOME="/home/HOMEPI/"

print_usage() {
    echo "Usage: $0 --domain=DOMAIN --server=SERVER"
    echo "  -d, --domain  Set the domain name"
    echo "  -s, --server-name  Set the server name"
    echo "  -cf, --csv-file   specify csv_file"
    echo "  -P, --default_password  default password will be P@ssw0rd"
    echo " -gn, --group-name primary group name"
    echo " -gid, --group-number primary group number"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "CSV File Structure:"
    echo "  The CSV file must be formatted as follows (including a header row):"
    echo "  Registration_No,First_Name,Surname,Initials,Email,Phone"
    echo ""
    echo "  Example CSV content:"
    echo "  Registration_No,First_Name,Surname,Initials,Email,Phone"
    echo "  2020CSC053,John,Doe,J,johndoe@email.com,0723456789"
    echo ""
    echo "Example Command:"
    echo "  ./script.sh --domain=homepi.local --server-name=ad-serv --csv-file=users.csv"
}

# Parsing arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -d | --domain=*) DOMAIN="${1#*=}" ;;
    -s | --server-name=*) SERVER_NAME="${1#*=}" ;;
    -cf | --csv-file=*) CSV_FILE="${1#*=}" ;;
    -P | --default_password=*) DEFAULT_PASSWORD="${1#*=}" ;;
    -gn | --group-name=*) PRI_GROUP="${1#*=}" ;;
    -gid | --group-number=*) PRI_GROUP_ID="${1#*=}" ;;
    -h | --help)
        print_usage
        exit 0
        ;;
    *)
        echo "Invalid parameters: $1"
        print_usage
        exit 1
        ;;
    esac
    shift
done

if [[ -z "$DOMAIN" || -z "$SERVER_NAME" ]]; then
    echo "Error: Both --domain and --server are required."
    print_usage
    exit 1
fi

echo "CSV_FILE ${CSV_FILE}, DOMAIN ${DOMAIN}, SERVER ${SERVER_NAME}"

# samba-tool user create 2020CSC055 --given-name="2020CSC052 Nerujan" --initials="S" --surname="Sathasivam" --uid-number=20055 --gid-number=1006 --profile-path="\\ad-serv.homepi.local\profiles\2020CSC055" --home-drive="P:" --home-directory="\\ad-serv.homepi.local\profiles\2020CSC055.V6" --unix-home="/home/HOMEPI/2020CSC055" --login-shell="/bin/bash"

# Parsing CSV
while IFS=',' read -r reg_num first_name surname initials email phone; do
    [[ "$reg_num" == "Registration_No" ]] && continue # skip the header

    batch_year="${reg_num:0:4}"
    batch_id="${reg_num:2:2}"
    department="${reg_num:4:-3}"
    index_number="${reg_num: -3:3}"

    if [[ -n "$initials" ]]; then
        initials_option="--initials=\"$initials\""
    else
        initials_option=""
    fi

    echo "Creating User: $reg_num $first_name"

    samba-tool user create $reg_num $DEFAULT_PASSWORD --given-name="$reg_num $first_name" \
        --surname="$surname" \
        --uid-number=$((${batch_id}${index_number})) \
        --gid-number=$((PRI_GROUP_ID)) \
        --profile-path="\\\\${SERVER_NAME}.${DOMAIN}\profiles\\$reg_num" \
        --login-shell=$LOGIN_SHELL \
        --unix-home="${UNIX_HOME}${reg_num}" \
        --home-drive="P:" \
        --home-directory="\\\\${SERVER_NAME}.${DOMAIN}\profiles\\$reg_num.V6" \
        --department="${department}" \
        --mail-address="$email" \
        --telephone="$phone" \
        $initials_option
    # --initials="$initials"
    # --job-title=""

    # mkdir -p "$home_dir"
    # chown "$username:$gid_number" "$home_dir"
    # chmod 700 "$home_dir"

done <"$CSV_FILE"
