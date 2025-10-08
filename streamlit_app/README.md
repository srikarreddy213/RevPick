## RevPick Streamlit App

### Prerequisites
- Python 3.9+
- A Supabase project with the schema in `RevPick/supabase_schema.sql` applied

### Install
```bash
pip install -r requirements.txt
```

### Configure secrets
Create `.streamlit/secrets.toml` in this folder:
```toml
SUPABASE_URL = "https://YOUR-PROJECT.supabase.co"
SUPABASE_ANON_KEY = "YOUR_PUBLIC_ANON_KEY"
```

### Run locally
```bash
streamlit run app.py
```

### Deploy options
- Streamlit Community Cloud: add the repo, app path `revpick/RevPick/streamlit_app`, entry `app.py`, deps `requirements.txt`. Set secrets.
- Docker/Cloud Run: build a simple image and run `streamlit run app.py --server.port $PORT --server.address 0.0.0.0`.

### Notes
- Products view supports ICE/EV, brand/name filters, and price cap.
- Customers view: list and create customers.
- Suggestions view: log product suggestions for a customer.

