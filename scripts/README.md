# EcoVolt IoT Simulator

This directory contains scripts for simulating EcoVolt IoT devices and testing the infrastructure.

## IoT Device Simulator

The `iot_simulator.py` script simulates electric bikes and battery swap stations publishing telemetry data to AWS IoT Core.

### Prerequisites

```bash
# Install required Python packages
pip install boto3

# Configure AWS credentials
aws configure
```

### Usage

#### Basic Usage

```bash
# Simulate 3 bikes and 2 stations (default)
python scripts/iot_simulator.py

# Simulate 10 bikes and 5 stations
python scripts/iot_simulator.py --bikes 10 --stations 5

# Use a different AWS region
python scripts/iot_simulator.py --region us-west-2

# Faster publishing (0.5 second interval)
python scripts/iot_simulator.py --interval 0.5
```

#### Advanced Usage

```bash
# High-volume simulation
python scripts/iot_simulator.py --bikes 50 --stations 10 --interval 0.5

# Single device testing
python scripts/iot_simulator.py --bikes 1 --stations 1 --interval 2
```

### Data Generated

#### Bike Telemetry (`ecovolt/bikes/{bike_id}/telemetry`)

Published every second per bike:

```json
{
  "bike_id": "bike-001",
  "timestamp": "2024-01-15T10:30:45.123456Z",
  "message_type": "telemetry",
  "battery": {
    "soc_percent": 75.5,
    "voltage_v": 51.2,
    "current_a": 15.3,
    "temperature_c": 32.5,
    "power_w": 783.4,
    "health_percent": 95.2
  },
  "motion": {
    "speed_kmh": 28.5,
    "trip_distance_km": 12.3,
    "is_moving": true
  },
  "location": {
    "latitude": -1.2765,
    "longitude": 36.8172,
    "altitude_m": 1650.5
  },
  "diagnostics": {
    "motor_temp_c": 38.2,
    "controller_temp_c": 35.7,
    "error_codes": []
  }
}
```

#### Station Energy Data (`ecovolt/stations/{station_id}/energy`)

Published every 5 seconds per station:

```json
{
  "station_id": "station-001",
  "timestamp": "2024-01-15T10:30:45.123456Z",
  "message_type": "energy",
  "battery_inventory": {
    "total_slots": 10,
    "charged_available": 6,
    "charging": 2,
    "empty_slots": 2
  },
  "energy": {
    "solar_output_kw": 12.5,
    "solar_capacity_kw": 15.0,
    "grid_power_kw": 2.3,
    "charging_power_kw": 14.8,
    "battery_storage_kwh": 35.2
  },
  "status": {
    "grid_connected": true,
    "operational": true,
    "temperature_c": 28.5
  }
}
```

#### Battery Swap Events (`ecovolt/stations/{station_id}/swap`)

Published when a swap occurs (randomly):

```json
{
  "station_id": "station-001",
  "timestamp": "2024-01-15T10:30:45.123456Z",
  "message_type": "swap",
  "swap_event": {
    "bike_id": "bike-042",
    "old_battery_id": "bat-1234",
    "new_battery_id": "bat-5678",
    "old_battery_soc": 15.2,
    "new_battery_soc": 98.5,
    "swap_duration_seconds": 67.3,
    "operator_id": "operator-03"
  },
  "post_swap_inventory": {
    "charged_available": 5,
    "charging": 3
  }
}
```

### Simulation Behavior

#### Bikes
- Start with 60-95% battery charge
- Randomly switch between moving and stopped states
- When moving:
  - Speed: 15-45 km/h
  - Battery drains 0.1-0.3% per second
  - GPS position updates (random walk)
- When stopped:
  - Speed: 0 km/h
  - Battery drains 0.01-0.05% per second (idle drain)
- Battery voltage: 48-54V (varies with SOC)
- Temperature rises with current draw

#### Stations
- 8-12 battery slots per station
- Solar output varies by time of day (peak at noon)
- Charging power: 3-5 kW per battery
- Grid power supplements solar when needed
- 95% grid uptime (occasional outages)
- Battery swaps occur randomly when charged batteries available
- Swap duration: 45-120 seconds

### Monitoring

Watch the output to see published messages:

```
✓ telemetry  | bike-001        | ecovolt/bikes/bike-001/telemetry
✓ telemetry  | bike-002        | ecovolt/bikes/bike-002/telemetry
✓ energy     | station-001     | ecovolt/stations/station-001/energy
✓ swap       | station-001     | ecovolt/stations/station-001/swap
```

### Troubleshooting

#### Authentication Errors

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check IoT endpoint
aws iot describe-endpoint --endpoint-type iot:Data-ATS
```

#### Permission Errors

Ensure your AWS credentials have permissions to publish to IoT Core:
- `iot:Publish`
- `iot:Connect`

#### No Data in Kinesis

1. Check IoT Rules are enabled:
   ```bash
   aws iot list-topic-rules
   ```

2. Verify Kinesis stream exists:
   ```bash
   aws kinesis list-streams
   ```

3. Check CloudWatch Logs for IoT Rule errors:
   ```bash
   aws logs tail /aws/iot/rules --follow
   ```

### Testing Tips

1. **Start Small**: Begin with 1-2 devices to verify connectivity
2. **Monitor CloudWatch**: Watch for data flowing through Kinesis
3. **Check Timestream**: Verify data is being stored in the database
4. **Scale Gradually**: Increase device count to test load handling
5. **Use Different Regions**: Test multi-region deployments

### Cost Considerations

- IoT Core charges per message published
- Kinesis charges per shard hour and PUT requests
- Consider using `--interval` to reduce message frequency during testing
- Stop the simulator when not actively testing

### Integration with Infrastructure

The simulator publishes to topics that match the IoT Rules defined in the infrastructure:

- `ecovolt/bikes/+/telemetry` → Kinesis → Lambda → Timestream
- `ecovolt/stations/+/energy` → Kinesis → Lambda → Timestream
- `ecovolt/stations/+/swap` → Kinesis → Lambda → Timestream

All data flows through the analytics pipeline for processing and storage.
