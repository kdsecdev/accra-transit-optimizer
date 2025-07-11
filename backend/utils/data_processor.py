import pandas as pd
import numpy as np
import gtfs_kit as gk
import folium
from datetime import datetime, timedelta
import json
from pathlib import Path

class AccraGTFSProcessor:
    """Process 2016 Accra GTFS data and generate synthetic GPS pings"""
    
    def __init__(self, gtfs_path):
        self.gtfs_path = gtfs_path
        self.feed = None
        self.stops_df = None
        self.routes_df = None
        self.stop_times_df = None
        self.synthetic_gps = None
        
    def load_gtfs_data(self):
        """Load and validate GTFS data"""
        print("Loading GTFS data...")
        self.feed = gk.read_feed(self.gtfs_path, dist_units='km')
        
        # Extract key dataframes
        self.stops_df = self.feed.stops.copy()
        self.routes_df = self.feed.routes.copy()
        self.stop_times_df = self.feed.stop_times.copy()
        
        print(f"Loaded {len(self.stops_df)} stops, {len(self.routes_df)} routes")
        return self
    
    def generate_synthetic_gps(self, num_days=30):
        """Generate synthetic GPS pings from GTFS stop times"""
        print("Generating synthetic GPS data...")
        
        # Get unique trips and their stop sequences
        trip_stops = self.stop_times_df.merge(
            self.stops_df[['stop_id', 'stop_lat', 'stop_lon']], 
            on='stop_id'
        )
        
        synthetic_data = []
        base_date = datetime(2016, 1, 1)
        
        for day in range(num_days):
            current_date = base_date + timedelta(days=day)
            
            # Sample trips for this day (simulate varying demand)
            daily_trips = trip_stops.sample(
                n=min(1000, len(trip_stops)), 
                replace=True
            )
            
            for _, row in daily_trips.iterrows():
                # Add realistic noise to coordinates
                lat_noise = np.random.normal(0, 0.001)  # ~100m variance
                lon_noise = np.random.normal(0, 0.001)
                
                # Create GPS ping
                gps_ping = {
                    'timestamp': current_date + timedelta(
                        hours=np.random.uniform(5, 22),  # Operating hours
                        minutes=np.random.uniform(0, 59)
                    ),
                    'latitude': row['stop_lat'] + lat_noise,
                    'longitude': row['stop_lon'] + lon_noise,
                    'stop_id': row['stop_id'],
                    'route_id': row.get('route_id', 'unknown'),
                    'occupancy': np.random.choice([0.2, 0.5, 0.8, 1.0], 
                                                p=[0.3, 0.4, 0.2, 0.1])  # Demand proxy
                }
                synthetic_data.append(gps_ping)
        
        self.synthetic_gps = pd.DataFrame(synthetic_data)
        self.synthetic_gps['hour'] = self.synthetic_gps['timestamp'].dt.hour
        self.synthetic_gps['day_of_week'] = self.synthetic_gps['timestamp'].dt.dayofweek
        
        print(f"Generated {len(self.synthetic_gps)} synthetic GPS pings")
        return self
    
    def create_demand_features(self):
        """Create hourly demand estimates from synthetic data"""
        print("Creating demand features...")
        
        # Aggregate by stop and hour
        demand_features = self.synthetic_gps.groupby(
            ['stop_id', 'hour', 'day_of_week']
        ).agg({
            'occupancy': ['mean', 'count'],
            'latitude': 'first',
            'longitude': 'first'
        }).reset_index()
        
        # Flatten column names
        demand_features.columns = [
            'stop_id', 'hour', 'day_of_week', 'avg_occupancy', 
            'trip_count', 'latitude', 'longitude'
        ]
        
        # Add features for ML
        demand_features['is_weekend'] = (demand_features['day_of_week'] >= 5).astype(int)
        demand_features['is_rush_hour'] = (
            ((demand_features['hour'] >= 7) & (demand_features['hour'] <= 9)) |
            ((demand_features['hour'] >= 17) & (demand_features['hour'] <= 19))
        ).astype(int)
        
        # Calculate demand score (0-100)
        demand_features['demand_score'] = (
            demand_features['avg_occupancy'] * demand_features['trip_count'] * 20
        ).clip(0, 100)
        
        return demand_features
    
    def create_interactive_map(self, save_path='../docs/accra_transit_map.html'):
        """Create interactive map with stops and routes"""
        print("Creating interactive map...")
        
        # Center map on Accra
        center_lat = self.stops_df['stop_lat'].mean()
        center_lon = self.stops_df['stop_lon'].mean()
        
        m = folium.Map(
            location=[center_lat, center_lon],
            zoom_start=12,
            tiles='OpenStreetMap'
        )
        
        # Add stops as markers
        for _, stop in self.stops_df.iterrows():
            folium.CircleMarker(
                location=[stop['stop_lat'], stop['stop_lon']],
                radius=5,
                popup=f"Stop: {stop['stop_name']}<br>ID: {stop['stop_id']}",
                color='blue',
                fill=True,
                fillColor='lightblue'
            ).add_to(m)
        
        # Add heatmap overlay for demand (if synthetic data exists)
        if self.synthetic_gps is not None:
            from folium.plugins import HeatMap
            heat_data = [[row['latitude'], row['longitude'], row['occupancy']] 
                        for _, row in self.synthetic_gps.iterrows()]
            HeatMap(heat_data).add_to(m)
        
        m.save(save_path)
        print(f"Map saved to {save_path}")
        return m