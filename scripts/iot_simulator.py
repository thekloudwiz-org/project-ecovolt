#!/usr/bin/env python3
"""
EcoVolt IoT Device Simulator

Simulates IoT devices publishing telemetry data to AWS IoT Core:
- Electric bikes with battery telemetry
- Battery swap stations with energy data
- Battery swap events

Topics match the infrastructure:
- ecovolt/bikes/{bike_id}/telemetry
- ecovolt/stations/{station_id}/energy
- ecovolt/stations/{station_id}/swap
"""

import boto3
import json
import random
import time
import argparse
import sys
from datetime import datetime, timedelta
from typing import Dict, Any

# Default configuration
DEFAULT_REGION = 'eu-central-1'

class BikeSimulator:
    """Simulates an electric bike with realistic telemetry patterns."""
    
    def __init__(self, bike_id: str):
        self.bike_id = bike_id
        self.soc = random.uniform(60.0, 95.0)  # Start with decent charge
        self.speed = 0.0
        self.is_moving = False
        self.trip_distance = 0.0
        # Nairobi coordinates (can be adjusted)
        self.lat = random.uniform(-1.29, -1.25)
        self.lon = random.uniform(36.8, 36.9)
        
    def get_telemetry(self) -> Dict[str, Any]:
        """Generate realistic bike telemetry."""
        # Simulate movement patterns
        if random.random() < 0.1:  # 10% chance to change state
            self.is_moving = not self.is_moving
        
        if self.is_moving:
            # Moving: consume battery, update speed and position
            self.speed = random.uniform(15.0, 45.0)  # km/h
            self.soc = max(5.0, self.soc - random.uniform(0.1, 0.3))
            self.trip_distance += self.speed / 3600  # Convert to km per second
            # Update GPS (small random walk)
            self.lat += random.uniform(-0.0001, 0.0001)
            self.lon += random.uniform(-0.0001, 0.0001)
        else:
            # Stopped
            self.speed = 0.0
            self.soc = max(5.0, self.soc - random.uniform(0.01, 0.05))  # Idle drain
        
        # Calculate derived metrics
        voltage = 48.0 + (self.soc / 100.0) * 6.0  # 48-54V system
        current = (self.speed / 45.0) * 25.0 if self.is_moving else random.uniform(0.1, 0.5)
        power = voltage * current
        battery_temp = 25.0 + (current / 25.0) * 20.0  # Temp rises with current
        
        return {
            "bike_id": self.bike_id,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "message_type": "telemetry",
            "battery": {
                "soc_percent": round(self.soc, 1),
                "voltage_v": round(voltage, 2),
                "current_a": round(current, 2),
                "temperature_c": round(battery_temp, 1),
                "power_w": round(power, 1),
                "health_percent": round(random.uniform(85.0, 100.0), 1)
            },
            "motion": {
                "speed_kmh": round(self.speed, 1),
                "trip_distance_km": round(self.trip_distance, 2),
                "is_moving": self.is_moving
            },
            "location": {
                "latitude": round(self.lat, 6),
                "longitude": round(self.lon, 6),
                "altitude_m": round(random.uniform(1600, 1700), 1)  # Nairobi elevation
            },
            "diagnostics": {
                "motor_temp_c": round(battery_temp + random.uniform(-5, 10), 1),
                "controller_temp_c": round(battery_temp + random.uniform(-3, 8), 1),
                "error_codes": []
            }
        }

class StationSimulator:
    """Simulates a battery swap station with solar panels."""
    
    def __init__(self, station_id: str):
        self.station_id = station_id
        self.total_slots = random.randint(8, 12)
        self.charged_batteries = random.randint(4, self.total_slots - 2)
        self.charging_batteries = random.randint(1, 3)
        self.solar_capacity_kw = random.uniform(10.0, 20.0)
        self.last_swap_time = datetime.utcnow() - timedelta(minutes=random.randint(5, 60))
        
    def get_energy_data(self) -> Dict[str, Any]:
        """Generate station energy metrics."""
        # Simulate solar output based on time of day (simplified)
        hour = datetime.utcnow().hour
        if 6 <= hour <= 18:  # Daylight hours
            solar_factor = 1.0 - abs(hour - 12) / 6.0  # Peak at noon
            solar_output = self.solar_capacity_kw * solar_factor * random.uniform(0.7, 1.0)
        else:
            solar_output = 0.0
        
        # Grid power usage
        charging_power = self.charging_batteries * random.uniform(3.0, 5.0)  # kW per battery
        grid_power = max(0, charging_power - solar_output)
        
        return {
            "station_id": self.station_id,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "message_type": "energy",
            "battery_inventory": {
                "total_slots": self.total_slots,
                "charged_available": self.charged_batteries,
                "charging": self.charging_batteries,
                "empty_slots": self.total_slots - self.charged_batteries - self.charging_batteries
            },
            "energy": {
                "solar_output_kw": round(solar_output, 2),
                "solar_capacity_kw": round(self.solar_capacity_kw, 2),
                "grid_power_kw": round(grid_power, 2),
                "charging_power_kw": round(charging_power, 2),
                "battery_storage_kwh": round(random.uniform(20.0, 50.0), 1)
            },
            "status": {
                "grid_connected": random.random() > 0.05,  # 95% uptime
                "operational": True,
                "temperature_c": round(random.uniform(20.0, 35.0), 1)
            }
        }
    
    def simulate_swap_event(self) -> Dict[str, Any]:
        """Generate a battery swap event."""
        # Only swap if we have charged batteries
        if self.charged_batteries > 0 and random.random() < 0.3:
            self.charged_batteries -= 1
            self.charging_batteries += 1
            self.last_swap_time = datetime.utcnow()
            
            swap_duration = random.uniform(45, 120)  # seconds
            
            return {
                "station_id": self.station_id,
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "message_type": "swap",
                "swap_event": {
                    "bike_id": f"bike-{random.randint(1, 100):03d}",
                    "old_battery_id": f"bat-{random.randint(1000, 9999)}",
                    "new_battery_id": f"bat-{random.randint(1000, 9999)}",
                    "old_battery_soc": round(random.uniform(5.0, 25.0), 1),
                    "new_battery_soc": round(random.uniform(95.0, 100.0), 1),
                    "swap_duration_seconds": round(swap_duration, 1),
                    "operator_id": f"operator-{random.randint(1, 5):02d}"
                },
                "post_swap_inventory": {
                    "charged_available": self.charged_batteries,
                    "charging": self.charging_batteries
                }
            }
        
        # Simulate charging completion
        if self.charging_batteries > 0 and random.random() < 0.2:
            self.charging_batteries -= 1
            self.charged_batteries += 1
        
        return None

class IoTSimulator:
    """Main simulator orchestrator."""
    
    def __init__(self, region: str, num_bikes: int, num_stations: int):
        self.region = region
        self.iot_client = boto3.client('iot-data', region_name=region)
        
        # Initialize simulators
        self.bikes = [BikeSimulator(f"bike-{i:03d}") for i in range(1, num_bikes + 1)]
        self.stations = [StationSimulator(f"station-{i:03d}") for i in range(1, num_stations + 1)]
        
        print(f"⚡ EcoVolt IoT Simulator")
        print(f"Region: {region}")
        print(f"Bikes: {num_bikes}")
        print(f"Stations: {num_stations}")
        print(f"Press CTRL+C to stop\n")
    
    def publish(self, topic: str, payload: Dict[str, Any]):
        """Publish message to IoT Core."""
        try:
            self.iot_client.publish(
                topic=topic,
                qos=1,
                payload=json.dumps(payload)
            )
            msg_type = payload.get('message_type', 'unknown')
            device_id = payload.get('bike_id') or payload.get('station_id')
            print(f"✓ {msg_type:10s} | {device_id:15s} | {topic}")
        except Exception as e:
            print(f"✗ Error publishing to {topic}: {e}", file=sys.stderr)
    
    def run(self, interval: float = 1.0):
        """Run the simulation loop."""
        iteration = 0
        
        try:
            while True:
                iteration += 1
                
                # Publish bike telemetry every iteration (high frequency)
                for bike in self.bikes:
                    telemetry = bike.get_telemetry()
                    topic = f"ecovolt/bikes/{bike.bike_id}/telemetry"
                    self.publish(topic, telemetry)
                
                # Publish station energy data every 5 iterations (lower frequency)
                if iteration % 5 == 0:
                    for station in self.stations:
                        energy_data = station.get_energy_data()
                        topic = f"ecovolt/stations/{station.station_id}/energy"
                        self.publish(topic, energy_data)
                
                # Simulate swap events occasionally
                if iteration % 10 == 0:
                    for station in self.stations:
                        swap_event = station.simulate_swap_event()
                        if swap_event:
                            topic = f"ecovolt/stations/{station.station_id}/swap"
                            self.publish(topic, swap_event)
                
                time.sleep(interval)
                
        except KeyboardInterrupt:
            print("\n\n🛑 Simulation stopped")
            print(f"Total iterations: {iteration}")

def main():
    parser = argparse.ArgumentParser(
        description='EcoVolt IoT Device Simulator',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Simulate 5 bikes and 2 stations
  python iot_simulator.py --bikes 5 --stations 2
  
  # Use different region and faster interval
  python iot_simulator.py --region eu-west-1 --interval 0.5
  
  # Simulate many devices
  python iot_simulator.py --bikes 50 --stations 10
        """
    )
    
    parser.add_argument('--region', type=str, default=DEFAULT_REGION,
                        help=f'AWS region (default: {DEFAULT_REGION})')
    parser.add_argument('--bikes', type=int, default=3,
                        help='Number of bikes to simulate (default: 3)')
    parser.add_argument('--stations', type=int, default=2,
                        help='Number of stations to simulate (default: 2)')
    parser.add_argument('--interval', type=float, default=1.0,
                        help='Publish interval in seconds (default: 1.0)')
    
    args = parser.parse_args()
    
    # Validate inputs
    if args.bikes < 1 or args.bikes > 1000:
        print("Error: Number of bikes must be between 1 and 1000", file=sys.stderr)
        sys.exit(1)
    
    if args.stations < 1 or args.stations > 100:
        print("Error: Number of stations must be between 1 and 100", file=sys.stderr)
        sys.exit(1)
    
    # Run simulator
    simulator = IoTSimulator(args.region, args.bikes, args.stations)
    simulator.run(args.interval)

if __name__ == "__main__":
    main()