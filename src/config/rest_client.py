import json
import urllib.parse
import urllib.request
from urllib.error import HTTPError, URLError
from typing import Any, Dict, List, Optional


class _Response:
	def __init__(self, data: Optional[List[Dict[str, Any]]]) -> None:
		self.data = data or []


class _Query:
	def __init__(self, base_url: str, table: str, headers: Dict[str, str]) -> None:
		self.base_url = base_url.rstrip("/")
		self.table = table
		self.headers = headers
		self._select = "*"
		self._filters: Dict[str, Any] = {}
		self._limit: Optional[int] = None
		self._payload: Optional[Dict[str, Any]] = None
		self._method: Optional[str] = None
		self._on_conflict: Optional[str] = None
		self._is_upsert: bool = False

	def select(self, fields: str) -> "_Query":
		self._select = fields
		self._method = "GET"
		return self

	def eq(self, key: str, value: Any) -> "_Query":
		self._filters[key] = value
		return self

	def limit(self, n: int) -> "_Query":
		self._limit = n
		return self

	def insert(self, data: Dict[str, Any]) -> "_Query":
		self._payload = data
		self._method = "POST"
		return self

	def upsert(self, data: List[Dict[str, Any]], on_conflict: str) -> "_Query":
		self._payload = {"_list": data}  # marker to indicate list payload
		self._method = "POST"
		self._on_conflict = on_conflict
		self._is_upsert = True
		return self

	def update(self, data: Dict[str, Any]) -> "_Query":
		self._payload = data
		self._method = "PATCH"
		return self

	def delete(self) -> "_Query":
		self._method = "DELETE"
		return self

	def execute(self) -> _Response:
		url = f"{self.base_url}/rest/v1/{urllib.parse.quote(self.table)}"
		params: Dict[str, str] = {"select": self._select}
		for k, v in self._filters.items():
			params[k] = f"eq.{v}"
		if self._limit is not None:
			params["limit"] = str(self._limit)
		if self._method in (None, "GET"):
			full_url = f"{url}?{urllib.parse.urlencode(params)}"
			headers = dict(self.headers)
			headers["Accept"] = "application/json"
			req = urllib.request.Request(full_url, headers=headers, method="GET")
			with urllib.request.urlopen(req) as resp:
				data = json.loads(resp.read().decode("utf-8"))
				return _Response(data if isinstance(data, list) else [])
		else:
			headers = dict(self.headers)
			headers["Content-Type"] = "application/json"
			prefer = ["return=representation"]
			if self._is_upsert:
				prefer.append("resolution=merge-duplicates")
			headers["Prefer"] = ",".join(prefer)
			if self._on_conflict:
				params["on_conflict"] = self._on_conflict
			# For non-GET, do not include select parameter unless upsert uses on_conflict
			params_non_get = dict(params)
			params_non_get.pop("select", None)
			full_url = f"{url}?{urllib.parse.urlencode(params_non_get)}" if params_non_get else url
			payload_obj: Any
			if isinstance(self._payload, dict) and "_list" in self._payload:
				payload_obj = self._payload["_list"]  # explicit bulk payload
			else:
				# For single inserts/updates, send object (not array)
				payload_obj = self._payload if self._payload is not None else {}
			payload_bytes = json.dumps(payload_obj).encode("utf-8") if self._method in ("POST", "PATCH") else None
			req = urllib.request.Request(full_url, data=payload_bytes, headers=headers, method=self._method)
			try:
				with urllib.request.urlopen(req) as resp:
					body = resp.read().decode("utf-8")
					try:
						data = json.loads(body)
						return _Response(data if isinstance(data, list) else [])
					except Exception:
						return _Response([])
			except HTTPError as e:
				# Try to parse error body for clarity
				err_text = e.read().decode("utf-8", errors="ignore")
				try:
					err_json = json.loads(err_text)
					err_msg = err_json.get("message") or err_text
				except Exception:
					err_msg = err_text
				raise RuntimeError(f"HTTP {e.code}: {err_msg}")
			except URLError as e:
				raise RuntimeError(f"Network error: {e.reason}")


class RestClient:
	def __init__(self, supabase_url: str, supabase_key: str) -> None:
		self.base_url = supabase_url.rstrip("/")
		self.headers = {
			"apikey": supabase_key,
			"Authorization": f"Bearer {supabase_key}",
		}

	def table(self, name: str) -> _Query:
		return _Query(self.base_url, name, self.headers)

