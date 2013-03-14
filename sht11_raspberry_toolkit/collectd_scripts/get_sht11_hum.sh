HOSTNAME="${COLLECTD_HOSTNAME:-localhost}"
INTERVAL="60"

while sleep "$INTERVAL"; do
        VALUE=$(sudo get_sht11_temp)
        echo "PUTVAL \"$HOSTNAME/temperature/temperature\" interval=$INTERVAL N:$VALUE"
done

