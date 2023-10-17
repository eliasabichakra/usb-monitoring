#!/bin/bash

# Function to list all USB devices
list_usb_devices() {
  lsusb
}

# Directory to monitor for USB names
dir_to_monitor="/home/elias/name_dir"

# Function to check if a name has more than 5 characters
has_more_than_5_characters() {
  local name="$1"
  if [ ${#name} -gt 5 ]; then
    return 0  # Return success (true)
  else
    return 1  # Return failure (false)
  fi
}

# Function to process a USB name file
process_usb_name_file() {
  local file="$1"
  while read -r name; do
    if has_more_than_5_characters "$name"; then
      echo "Name with more than 5 characters: $name"
    fi
  done < "$file"
}

# Create a temporary store for the current session
temp_store="/tmp/temp_store.txt"

# Initialize the temporary store
> "$temp_store"

# Initialize a flag to track if USB devices are connected
usb_connected=false

# Trap Ctrl+C to clear the temporary file and exit
trap 'echo "Ctrl+C pressed. Clearing temporary file."; rm -f "$temp_store"; exit' INT

# Infinite loop
while true; do
  # Get the current list of USB devices
  current_list=$(list_usb_devices)

  # If the initial list is empty, set it to the current list
  if [ -z "$initial_list" ]; then
    initial_list="$current_list"
  fi

  # Use diff to find differences between the lists
  diff_output=$(diff <(echo "$initial_list") <(echo "$current_list"))

  # Check if there are differences
  if [ -n "$diff_output" ]; then
    echo "USB device change detected:"
    echo "$diff_output"

    # Check if the diff is already in the temporary store
    if ! grep -qF "$diff_output" "$temp_store"; then
      # If not, append it to the temporary store
      echo "$diff_output" >> "$temp_store"
      echo "usb is already used"
      # Check if the device has already been processed
      if [ "$usb_connected" = false ]; then
        usb_connected=true
        for file in "$dir_to_monitor/"name*; do
          if [ -e "$file" ]; then
            process_usb_name_file "$file"
          fi
        done
      fi
    fi
  fi

  # Update the initial list to match the current list
  initial_list="$current_list"

  sleep 5  # Delay between checks (in seconds)
done
