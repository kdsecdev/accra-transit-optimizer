import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
import json

class RouteOptimizer:
    """Optimize route coverage using clustering and graph algorithms"""
    
    def __init__(self):
        self.stop_clusters = None
        self.optimization_results = None
        
    def cluster_stops(self, stops_df, n_clusters=20):
        """Cluster stops for route optimization"""
        print(f"Clustering stops into {n_clusters} groups...")
        
        # Prepare coordinates
        coords = stops_df[['stop_lat', 'stop_lon']].values
        
        # Perform clustering
        kmeans = KMeans(n_clusters=n_clusters, random_state=42)
        stops_df['cluster'] = kmeans.fit_predict(coords)
        
        self.stop_clusters = {
            'centers': kmeans.cluster_centers_,
            'labels': kmeans.labels_,
            'stops_df': stops_df
        }
        
        print(f"Stops clustered into {n_clusters} groups")
        return self
    
    def suggest_new_routes(self, demand_df, max_routes=5):
        """Suggest new routes based on demand patterns"""
        print("Analyzing demand patterns for route suggestions...")
        
        # Find high-demand areas with low coverage
        high_demand_stops = demand_df[
            demand_df['demand_score'] > demand_df['demand_score'].quantile(0.75)
        ]
        
        suggestions = []
        
        for cluster_id in high_demand_stops['stop_id'].unique()[:max_routes]:
            cluster_stops = high_demand_stops[
                high_demand_stops['stop_id'] == cluster_id
            ]
            
            avg_demand = cluster_stops['demand_score'].mean()
            peak_hours = cluster_stops.groupby('hour')['demand_score'].mean().idxmax()
            
            suggestion = {
                'suggested_route_id': f"new_route_{cluster_id}",
                'center_lat': cluster_stops['latitude'].mean(),
                'center_lon': cluster_stops['longitude'].mean(),
                'estimated_demand': avg_demand,
                'peak_hour': peak_hours,
                'coverage_stops': len(cluster_stops),
                'priority_score': avg_demand * len(cluster_stops)
            }
            
            suggestions.append(suggestion)
        
        # Sort by priority
        suggestions.sort(key=lambda x: x['priority_score'], reverse=True)
        
        self.optimization_results = suggestions
        print(f"Generated {len(suggestions)} route suggestions")
        return suggestions