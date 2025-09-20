#!/bin/bash

# Check for root
if [[ $EUID -ne 0 ]]; then
  echo "Run this script as root"
  exit 1
fi

UDEV_RULES_FILE="/etc/udev/rules.d/51-android.rules"
TEMP_BEFORE="/tmp/usb_before.txt"
TEMP_AFTER="/tmp/usb_after.txt"

echo "Saving current USB device list..."
lsusb >"$TEMP_BEFORE"

echo "Connect the new device via USB."
read -p "Press Enter once the device is connected..."

echo "Scanning updated USB device list..."
lsusb >"$TEMP_AFTER"

# Find new lines (devices) added
NEW_DEVICES=$(comm -13 <(sort "$TEMP_BEFORE") <(sort "$TEMP_AFTER"))

if [[ -z "$NEW_DEVICES" ]]; then
  echo "No new USB devices detected."
  rm -f "$TEMP_BEFORE" "$TEMP_AFTER"
  exit 1
fi

echo "New USB device(s) detected:"
echo "$NEW_DEVICES"

# Parse vendor and product IDs from new devices
declare -A NEW_IDS
while read -r line; do
  id=$(echo "$line" | awk '{print $6}')
  vendor=${id%%:*}
  product=${id##*:}
  NEW_IDS["$vendor:$product"]=1
done <<<"$NEW_DEVICES"

# Ensure rules file exists
if [[ ! -f "$UDEV_RULES_FILE" ]]; then
  echo "# Udev rules for Android devices (auto-generated)" >"$UDEV_RULES_FILE"
fi

# Check which IDs are already present in the rules file
for key in "${!NEW_IDS[@]}"; do
  vendor=${id%%:*}
  product=${id##*:}
  # Check if this vendor/product is already in the rules file
  if grep -q "ATTR{idVendor}==\"$vendor\"" "$UDEV_RULES_FILE" && grep -q "ATTR{idProduct}==\"$product\"" "$UDEV_RULES_FILE"; then
    echo "Device $vendor:$product already present in rules file, skipping."
  else
    echo "Adding new rule for device $vendor:$product"
    echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"$vendor\", ATTR{idProduct}==\"$product\", MODE=\"0666\", GROUP=\"plugdev\", SYMLINK+=\"android\"" >>"$UDEV_RULES_FILE"
  fi
done

chmod a+r "$UDEV_RULES_FILE"

echo "Reloading Udev rules..."
udevadm control --reload-rules
udevadm trigger

echo "Udev rules updated."

# Clean up
rm -f "$TEMP_BEFORE" "$TEMP_AFTER"
