import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.preprocessing import StandardScaler
import joblib
from pathlib import Path

class DemandPredictor:
    """Predict hourly ridership demand using ML"""
    
    def __init__(self):
        self.model = RandomForestRegressor(n_estimators=100, random_state=42)
        self.scaler = StandardScaler()
        self.is_trained = False
        
    def prepare_features(self, demand_df):
        """Prepare features for ML model"""
        features = [
            'hour', 'day_of_week', 'is_weekend', 'is_rush_hour',
            'latitude', 'longitude', 'avg_occupancy', 'trip_count'
        ]
        
        X = demand_df[features].copy()
        y = demand_df['demand_score'].copy()
        
        return X, y
    
    def train(self, demand_df):
        """Train the demand prediction model"""
        print("Training demand prediction model...")
        
        X, y = self.prepare_features(demand_df)
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        
        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train model
        self.model.fit(X_train_scaled, y_train)
        
        # Evaluate
        y_pred = self.model.predict(X_test_scaled)
        mae = mean_absolute_error(y_test, y_pred)
        rmse = np.sqrt(mean_squared_error(y_test, y_pred))
        r2 = r2_score(y_test, y_pred)
        
        print(f"Model Performance:")
        print(f"MAE: {mae:.2f}")
        print(f"RMSE: {rmse:.2f}")
        print(f"R²: {r2:.3f}")
        
        self.is_trained = True
        return self
    
    def predict_demand(self, stop_id, hour, day_of_week, latitude, longitude):
        """Predict demand for specific stop and time"""
        if not self.is_trained:
            raise ValueError("Model not trained yet!")
        
        # Create feature vector
        features = np.array([[
            hour, day_of_week, 
            1 if day_of_week >= 5 else 0,  # is_weekend
            1 if (7 <= hour <= 9) or (17 <= hour <= 19) else 0,  # is_rush_hour
            latitude, longitude,
            0.5,  # avg_occupancy (default)
            10    # trip_count (default)
        ]])
        
        features_scaled = self.scaler.transform(features)
        demand_score = self.model.predict(features_scaled)[0]
        
        return max(0, min(100, demand_score))  # Clip to 0-100
    
    def save_model(self, model_path='../models/demand_predictor.pkl'):
        """Save trained model"""
        Path(model_path).parent.mkdir(parents=True, exist_ok=True)
        joblib.dump({
            'model': self.model,
            'scaler': self.scaler,
            'is_trained': self.is_trained
        }, model_path)
        print(f"Model saved to {model_path}")
    
    def load_model(self, model_path='../models/demand_predictor.pkl'):
        """Load trained model"""
        data = joblib.load(model_path)
        self.model = data['model']
        self.scaler = data['scaler']
        self.is_trained = data['is_trained']
        print(f"Model loaded from {model_path}")