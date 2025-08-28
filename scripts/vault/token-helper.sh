#!/bin/bash
# Vault Token Helper Script
# Manages Vault authentication tokens per server address
# Usage: token-helper.sh [get|store|erase]

function write_error(){ >&2 echo "$@"; }

# Customize the hash key for tokens. Currently, we remove the strings
# 'https://', '.', and ':' from the passed address (Vault address environment
# by default) because jq has trouble with special characeters in JSON field
# names
function createHashKey {
  
  local key=""

  if [[ -z "${1}" ]] ; then key="${VAULT_ADDR}" 
  else                      key="${1}"
  fi
  
  # We index the token according to the Vault server address by default so
  # return an error if the address is empty
  if [[ -z "${key}" ]] ; then
    write_error "Error: VAULT_ADDR environment variable unset."
    exit 100
  fi

  # Handle both http and https protocols
  key=${key//"https://"/""}
  key=${key//"http://"/""}
  key=${key//"."/"_"}
  key=${key//":"/"_"}

  echo "addr-${key}"
}

# Use .vault_tokens (plural) to avoid conflicts with default .vault-token
TOKEN_FILE="${HOME}/.vault_tokens"
KEY=$(createHashKey)
TOKEN="null"

# If the token file does not exist, create it with restricted permissions
if [ ! -f "${TOKEN_FILE}" ] ; then
   echo "{}" > "${TOKEN_FILE}"
   chmod 600 "${TOKEN_FILE}"  # Only owner can read/write
fi

case "${1}" in
    "get")

      # Read the current JSON data and pull the token associated with ${KEY}
      TOKEN=$(jq --arg key "${KEY}" -r '.[$key]' < "${TOKEN_FILE}")
      
      # If the token != to the string "null", print the token to stdout 
      # jq returns "null" if the key was not found in the JSON data
      if [ ! "${TOKEN}" == "null" ] ; then
        echo "${TOKEN}"
      fi
      exit 0
    ;;

    "store")
      
      # Get the token from stdin
      read TOKEN

      # Read the current JSON data and add a new entry
      JSON=$(
        jq                      \
        --arg key "${KEY}"      \
        --arg token "${TOKEN}"  \
        '.[$key] = $token' ${TOKEN_FILE}
      )
      
    ;;

    "erase")
      # Read the current JSON data and remove the entry if it exists
      JSON=$(
        jq                      \
        --arg key "${KEY}"      \
        --arg token "${TOKEN}"  \
        'del(.[$key])' ${TOKEN_FILE}
      )
    
    ;;

    *)
      # change to stderr for real code
      write_error "Error: Provide a valid command: get, store, or erase."
      exit 101
esac

# Update the JSON file and return success
echo "$JSON" | jq "." > "${TOKEN_FILE}"
chmod 600 "${TOKEN_FILE}"  # Ensure permissions remain restricted
exit 0
