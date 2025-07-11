"""
Enhanced API Routes for Accra Transit Optimizer
"""

from fastapi import APIRouter, HTTPException, Query, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import sys
import os
import json
import pandas as pd
from datetime import datetime, timedelta
import numpy as np

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models.demand_predictor import DemandPredictor
from models.route_optimizer import RouteOptimizer
from utils.data_processor import AccraGTFSProcessor

router = APIRouter()

# Global variables for loaded models and data
demand_predictor = DemandPredictor()
route_optimizer = RouteOptimizer()
gtfs_processor = None
stops_data = None
routes_data = None

# Load models and data at startup
def load_models():
    global demand_predictor, route_optimizer, gtfs_processor, stops_data, routes_data
    try:
        demand_predictor.load_model("../models/demand_predictor.pkl")
        print("✅ Demand predictor loaded successfully")
        
        # Load processed data
        if os.path.exists("../data/processed/demand_features.csv"):
            demand_features = pd.read_csv("../data/processed/demand_features.csv")
            print("✅ Demand features loaded")
        
        if os.path.exists("../data/processed/synthetic_gps.csv"):
            synthetic_gps = pd.read_csv("../data/processed/synthetic_gps.csv")
            print("✅ Synthetic GPS data loaded")
            
        # Load GTFS data if available
        if os.path.exists("../data/gtfs/"):
            gtfs_processor = AccraGTFSProcessor("../data/gtfs/")
            try:
                gtfs_processor.load_gtfs_data()
                stops_data = gtfs_processor.stops_df
                routes_data = gtfs_processor.routes_df
                print("✅ GTFS data loaded successfully")
            except Exception as e:
                print(f"⚠️ GTFS data loading failed: {e}")
        
    except Exception as e:
        print(f"⚠️ Model loading failed: {e}")

# Load on startup
load_models()

# ===== PYDANTIC MODELS =====

class DemandRequest(BaseModel):
    stop_id: str = Field(..., description="Stop ID")
    hour: int = Field(..., ge=0, le=23, description="Hour of day (0-23)")
    day_of_week: int = Field(..., ge=0, le=6, description="Day of week (0=Monday)")
    latitude: float = Field(..., description="Stop latitude")
    longitude: float = Field(..., description="Stop longitude")

class DemandResponse(BaseModel):
    stop_id: str
    demand_score: float
    demand_level: str
    peak_hour: bool
    recommendations: List[str]

class RouteRequest(BaseModel):
    max_routes: int = Field(default=5, ge=1, le=20)
    min_demand_threshold: float = Field(default=30.0, ge=0, le=100)

class RouteResponse(BaseModel):
    route_id: str
    center_lat: float
    center_lon: float
    estimated_demand: float
    peak_hour: int
    coverage_stops: int
    priority_score: float
    viability: str

class StopInfo(BaseModel):
    stop_id: str
    stop_name: str
    latitude: float
    longitude: float
    current_demand: Optional[float] = None

class GPSPing(BaseModel):
    latitude: float
    longitude: float
    timestamp: datetime
    occupancy: float = Field(ge=0, le=1)
    route_id: Optional[str] = None

class AnalyticsResponse(BaseModel):
    total_stops: int
    total_routes: int
    avg_demand: float
    peak_hours: List[int]
    high_demand_areas: List[Dict[str, Any]]
    recommendations: List[str]

# ===== API ENDPOINTS =====

@router.post("/predict_demand", response_model=DemandResponse)
async def predict_demand(request: DemandRequest):
    """Predict demand for a specific stop and time with recommendations"""
    try:
        if not demand_predictor.is_trained:
            raise HTTPException(status_code=503, detail="Model not trained yet")
        
        demand_score = demand_predictor.predict_demand(
            request.stop_id,
            request.hour,
            request.day_of_week,
            request.latitude,
            request.longitude
        )
        
        # Determine demand level
        if demand_score >= 75:
            demand_level = "Very High"
        elif demand_score >= 50:
            demand_level = "High"
        elif demand_score >= 25:
            demand_level = "Medium"
        else:
            demand_level = "Low"
        
        # Check if peak hour
        peak_hour = (7 <= request.hour <= 9) or (17 <= request.hour <= 19)
        
        # Generate recommendations
        recommendations = []
        if demand_score > 70:
            recommendations.append("Consider increasing service frequency")
            if peak_hour:
                recommendations.append("Deploy additional vehicles during peak hours")
        elif demand_score < 30:
            recommendations.append("Consider reducing service frequency")
            recommendations.append("Evaluate route viability")
        
        if request.day_of_week >= 5:  # Weekend
            recommendations.append("Weekend service pattern detected")
        
        return DemandResponse(
            stop_id=request.stop_id,
            demand_score=round(demand_score, 1),
            demand_level=demand_level,
            peak_hour=peak_hour,
            recommendations=recommendations
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

@router.post("/suggest_routes", response_model=List[RouteResponse])
async def suggest_routes(request: RouteRequest):
    """Get optimized route suggestions based on demand analysis"""
    try:
        # Load route suggestions
        suggestions_file = "../data/processed/route_suggestions.json"
        if not os.path.exists(suggestions_file):
            raise HTTPException(status_code=404, detail="Route suggestions not found. Run training first.")
        
        with open(suggestions_file, 'r') as f:
            suggestions = json.load(f)
        
        # Filter by demand threshold
        filtered_suggestions = [
            s for s in suggestions 
            if s.get('estimated_demand', 0) >= request.min_demand_threshold
        ]
        
        # Convert to response format
        route_responses = []
        for suggestion in filtered_suggestions[:request.max_routes]:
            
            # Determine viability
            demand = suggestion.get('estimated_demand', 0)
            if demand >= 70:
                viability = "High Viability"
            elif demand >= 40:
                viability = "Medium Viability"
            else:
                viability = "Low Viability"
            
            route_responses.append(RouteResponse(
                route_id=suggestion.get('suggested_route_id', 'unknown'),
                center_lat=suggestion.get('center_lat', 0),
                center_lon=suggestion.get('center_lon', 0),
                estimated_demand=suggestion.get('estimated_demand', 0),
                peak_hour=suggestion.get('peak_hour', 8),
                coverage_stops=suggestion.get('coverage_stops', 0),
                priority_score=suggestion.get('priority_score', 0),
                viability=viability
            ))
        
        return route_responses
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Route suggestion error: {str(e)}")

@router.get("/stops", response_model=List[StopInfo])
async def get_stops(
    limit: int = Query(default=100, ge=1, le=1000),
    include_demand: bool = Query(default=False)
):
    """Get all stops information with optional demand data"""
    try:
        if stops_data is None:
            raise HTTPException(status_code=503, detail="Stops data not loaded")
        
        stops_sample = stops_data.head(limit)
        
        stops_info = []
        for _, stop in stops_sample.iterrows():
            stop_info = StopInfo(
                stop_id=stop['stop_id'],
                stop_name=stop.get('stop_name', f"Stop {stop['stop_id']}"),
                latitude=stop['stop_lat'],
                longitude=stop['stop_lon']
            )
            
            # Add current demand if requested
            if include_demand and demand_predictor.is_trained:
                try:
                    current_hour = datetime.now().hour
                    current_day = datetime.now().weekday()
                    
                    demand = demand_predictor.predict_demand(
                        stop['stop_id'],
                        current_hour,
                        current_day,
                        stop['stop_lat'],
                        stop['stop_lon']
                    )
                    stop_info.current_demand = round(demand, 1)
                except:
                    stop_info.current_demand = None
            
            stops_info.append(stop_info)
        
        return stops_info
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stops data error: {str(e)}")

@router.get("/analytics", response_model=AnalyticsResponse)
async def get_analytics():
    """Get comprehensive analytics about the transit system"""
    try:
        analytics = {
            "total_stops": 0,
            "total_routes": 0,
            "avg_demand": 0.0,
            "peak_hours": [8, 17],  # Default peak hours
            "high_demand_areas": [],
            "recommendations": []
        }
        
        # Load basic stats
        if stops_data is not None:
            analytics["total_stops"] = len(stops_data)
        
        if routes_data is not None:
            analytics["total_routes"] = len(routes_data)
        
        # Load demand data if available
        demand_file = "../data/processed/demand_features.csv"
        if os.path.exists(demand_file):
            demand_df = pd.read_csv(demand_file)
            analytics["avg_demand"] = float(demand_df['demand_score'].mean())
            
            # Find peak hours
            hourly_demand = demand_df.groupby('hour')['demand_score'].mean()
            top_hours = hourly_demand.nlargest(3).index.tolist()
            analytics["peak_hours"] = [int(h) for h in top_hours]
            
            # Find high demand areas
            high_demand = demand_df[demand_df['demand_score'] > demand_df['demand_score'].quantile(0.8)]
            for _, area in high_demand.head(5).iterrows():
                analytics["high_demand_areas"].append({
                    "stop_id": area['stop_id'],
                    "latitude": area['latitude'],
                    "longitude": area['longitude'],
                    "demand_score": round(area['demand_score'], 1)
                })
        
        # Generate recommendations
        recommendations = [
            "Focus on high-demand areas for service improvements",
            "Consider dynamic pricing during peak hours",
            "Optimize routes based on demand patterns",
        ]
        
        if analytics["avg_demand"] > 60:
            recommendations.append("Overall high demand detected - consider fleet expansion")
        elif analytics["avg_demand"] < 30:
            recommendations.append("Low demand areas need route optimization")
        
        analytics["recommendations"] = recommendations
        
        return AnalyticsResponse(**analytics)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analytics error: {str(e)}")

@router.post("/submit_gps")
async def submit_gps_data(gps_data: List[GPSPing]):
    """Submit new GPS pings for real-time updates"""
    try:
        # Save GPS data to file
        gps_file = "../data/processed/realtime_gps.csv"
        
        # Convert to DataFrame
        gps_df = pd.DataFrame([ping.dict() for ping in gps_data])
        
        # Append to existing file or create new
        if os.path.exists(gps_file):
            existing_df = pd.read_csv(gps_file)
            combined_df = pd.concat([existing_df, gps_df], ignore_index=True)
        else:
            combined_df = gps_df
        
        # Keep only recent data (last 7 days)
        combined_df['timestamp'] = pd.to_datetime(combined_df['timestamp'])
        cutoff_date = datetime.now() - timedelta(days=7)
        combined_df = combined_df[combined_df['timestamp'] >= cutoff_date]
        
        # Save
        combined_df.to_csv(gps_file, index=False)
        
        return {
            "status": "success",
            "message": f"Received {len(gps_data)} GPS pings",
            "total_records": len(combined_df)
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"GPS submission error: {str(e)}")

@router.get("/health")
async def health_check():
    """Comprehensive health check"""
    health_status = {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "services": {
            "demand_predictor": demand_predictor.is_trained,
            "gtfs_data": gtfs_processor is not None,
            "stops_data": stops_data is not None,
            "routes_data": routes_data is not None
        }
    }
    
    # Check if all services are working
    all_healthy = all(health_status["services"].values())
    health_status["status"] = "healthy" if all_healthy else "degraded"
    
    return health_status
