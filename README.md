# 🚌 Accra Transit Optimizer

**AI-powered transit optimization for Accra's public transport network (Trotros)**  
Built with **Flutter frontend** + **FastAPI backend** + **ML route and demand prediction models**.

---

## 📦 Project Structure

```
accra-transit-optimizer/
│
├── backend/                  # FastAPI backend
│   ├── api/                  # API routes and logic
│   ├── models/               # Trained ML models (demand predictor, route optimizer)
│   ├── utils/                # GTFS and data processing tools
│   ├── data/                 # GTFS data and processed datasets
│   ├── main.py               # FastAPI app
│   └── requirements.txt      # Python dependencies
│
├── frontend/                 # Flutter frontend
│   ├── lib/
│   │   ├── screens/          # UI screens (e.g., home_screen.dart)
│   │   ├── services/         # API service (api_service.dart)
│   │   ├── providers/        # App state logic (transit_provider.dart)
│   │   └── main.dart         # Flutter entry point
│   └── pubspec.yaml          # Flutter dependencies
```

---

## 🚀 Features

✅ GTFS data processing  
✅ ML-powered demand prediction  
✅ Optimized route suggestions  
✅ Live analytics dashboard  
✅ Flutter map view with stops and routes  
✅ Realtime GPS data support  
✅ Cross-platform: Android, iOS, Web, Windows

---

## 🧠 Tech Stack

| Layer     | Technology                  |
|-----------|-----------------------------|
| Backend   | Python, FastAPI, Pandas, Scikit-learn, XGBoost |
| Frontend  | Flutter, Provider, Flutter Map |
| Mapping   | OpenStreetMap + OSMnx       |
| ML Models | Demand prediction, Route optimization |
| Data      | GTFS (Accra), GPS, synthetic data |

---

## ⚙️ Setup Instructions

### 🔹 Backend (FastAPI)

> Requires Python 3.10 or 3.11 (avoid 3.12+)

```bash
cd backend/
python -m venv venv
source venv/bin/activate      # On Windows: venv\Scripts\activate
pip install --upgrade pip
pip install -r requirements.txt
uvicorn main:app --reload
```

- API Docs: [http://localhost:8000/docs](http://localhost:8000/docs)
- Health Check: `GET /health`

---

### 🔹 Frontend (Flutter)

> Requires Flutter 3.x. Use `flutter doctor` to confirm setup.

```bash
cd frontend/
flutter create .              # Repairs missing platform folders (android/, web/, etc.)
flutter pub get
flutter run -d chrome         # Or use `-d android`, `-d windows`, etc.
```

---

## 📡 API Overview

- `POST /api/v1/predict_demand` → Predicts demand at a given stop and time  
- `POST /api/v1/suggest_routes` → Returns optimized route suggestions  
- `GET  /api/v1/stops`          → Returns stop data (with optional demand)  
- `GET  /api/v1/analytics`      → High-level system analytics  
- `POST /api/v1/submit_gps`     → Submit real-time GPS data  

Explore endpoints at `/docs`.

---

## 📍 Map and Data Visualization

- Uses `flutter_map` + `latlong2` to show:
  - GTFS stops with markers
  - Suggested routes and high-demand areas
  - On-tap demand prediction UI

---

## 🧪 Sample GTFS Dataset

Ensure you place the 2016 Accra GTFS data in:
```
backend/data/gtfs/
```

---

## 🛠️ TODOs & Enhancements

- [ ] Live bus tracking via GPS feed
- [ ] Authentication & admin dashboard
- [ ] Deploy on Firebase + Render
- [ ] Clustering of stops & demand heatmap
- [ ] Schedule optimization using OR-Tools

---

## 💡 Credits

- **Lead Developer**: [Caleb Botchway / DEVKD.]  
- **Data**: [Accra GTFS, Synthetic GPS]  
- **Frameworks**: FastAPI, Flutter, Scikit-learn, OSMnx, GTFS-Kit

---

## 📜 License

MIT License.  
Use freely, contribute responsibly.

---

🚀 _"Optimizing Accra’s future, one route at a time!"_
