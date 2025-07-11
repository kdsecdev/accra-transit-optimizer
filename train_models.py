import sys
import os
sys.path.append('backend')

from backend.utils.data_processor import AccraGTFSProcessor
from backend.models.demand_predictor import DemandPredictor
from backend.models.route_optimizer import RouteOptimizer
import json

def main():
    """Execute model training pipeline"""
    print("=== ACCRA TRANSIT OPTIMIZER - MODEL TRAINING ===")
    
    # Initialize processor
    processor = AccraGTFSProcessor("data/gtfs/")
    
    # Step 1: Data processing
    print("\n--- STEP 1: DATA PROCESSING ---")
    processor.load_gtfs_data()
    processor.generate_synthetic_gps(num_days=30)
    
    # Create demand features
    demand_features = processor.create_demand_features()
    
    # Save processed data
    os.makedirs('data/processed', exist_ok=True)
    demand_features.to_csv('data/processed/demand_features.csv', index=False)
    processor.synthetic_gps.to_csv('data/processed/synthetic_gps.csv', index=False)
    
    # Create interactive map
    os.makedirs('docs', exist_ok=True)
    processor.create_interactive_map('docs/accra_transit_map.html')
    
    # Step 2: Train AI models
    print("\n--- STEP 2: AI MODEL TRAINING ---")
    
    # Train demand predictor
    demand_predictor = DemandPredictor()
    demand_predictor.train(demand_features)
    demand_predictor.save_model('models/demand_predictor.pkl')
    
    # Test prediction
    test_prediction = demand_predictor.predict_demand(
        stop_id='test_stop',
        hour=8,  # Rush hour
        day_of_week=1,  # Tuesday
        latitude=5.6037,  # Accra coordinates
        longitude=-0.1870
    )
    print(f"Test prediction (rush hour): {test_prediction:.1f}")
    
    # Route optimization
    route_optimizer = RouteOptimizer()
    route_optimizer.cluster_stops(processor.stops_df, n_clusters=15)
    route_suggestions = route_optimizer.suggest_new_routes(demand_features)
    
    # Save route suggestions
    with open('data/processed/route_suggestions.json', 'w') as f:
        json.dump(route_suggestions, f, indent=2, default=str)
    
    print("\n=== MODEL TRAINING COMPLETE ===")
    print("✅ GTFS data processed")
    print("✅ Synthetic GPS generated")
    print("✅ Interactive map created")
    print("✅ AI models trained and saved")
    print("✅ Route suggestions generated")
    print("\nNext: Run 'python backend/main.py' to start the API!")

if __name__ == "__main__":
    main()