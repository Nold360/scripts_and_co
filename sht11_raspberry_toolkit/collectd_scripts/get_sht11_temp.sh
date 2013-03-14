HOSTNAME="${COLLECTD_HOSTNAME:-localhost}"
INTERVAL="120"

while sleep "$INTERVAL"; do
        VALUE=$(sudo get_sht11_hum)
        echo "PUTVAL \"$HOSTNAME/humidity/humidity\" interval=$INTERVAL N:$VALUE"
done
