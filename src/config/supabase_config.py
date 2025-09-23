import os
from pathlib import Path
from typing import Optional

# Zero-dep REST client adapter for Supabase PostgREST
from .rest_client import RestClient

# Minimal .env loader (no external deps)
def _load_dotenv_minimal() -> None:
	"""Load .env from probable project roots into os.environ if present."""
	candidates = [
		Path(__file__).resolve().parents[2],  # repo root
		Path(__file__).resolve().parents[1],  # src
		Path.cwd(),
	]
	for base in candidates:
		dotenv_path = base / ".env"
		if dotenv_path.exists():
			try:
				for line in dotenv_path.read_text(encoding="utf-8").splitlines():
					line = line.strip()
					if not line or line.startswith("#") or "=" not in line:
						continue
					key, value = line.split("=", 1)
					key = key.strip()
					value = value.strip().strip('"').strip("'")
					if key and key not in os.environ:
						os.environ[key] = value
			except Exception:
				pass
			break

# Attempt to load before reading vars
_load_dotenv_minimal()

_SUPABASE_URL = os.getenv("SUPABASE_URL")
_SUPABASE_KEY = os.getenv("SUPABASE_KEY")

_cached_client: Optional[RestClient] = None


def get_client() -> RestClient:
	"""Return a cached REST client using SUPABASE_URL and SUPABASE_KEY from the environment."""
	global _cached_client
	if _cached_client is None:
		if not _SUPABASE_URL or not _SUPABASE_KEY:
			raise RuntimeError("SUPABASE_URL and SUPABASE_KEY must be set in environment")
		_cached_client = RestClient(_SUPABASE_URL, _SUPABASE_KEY)
	return _cached_client
