from typing import Any, Dict, List, Optional

from config.supabase_config import get_client
from dao.product_dao import ProductDAO


class ProductService:
	def __init__(self) -> None:
		self.dao = ProductDAO(get_client())

	def add_or_update_bike(self, data: Dict[str, Any]) -> Dict[str, Any]:
		prod_id = data.get("prod_id")
		if prod_id:
			updated = self.dao.update(prod_id, data)
			return updated or {}
		return self.dao.create(data)

	def list_bikes(
		self,
		category_id: Optional[str] = None,
		brand: Optional[str] = None,
		min_price: Optional[float] = None,
		max_price: Optional[float] = None,
		min_engine_cc: Optional[int] = None,
		max_engine_cc: Optional[int] = None,
		location: Optional[str] = None,
		is_electric: Optional[bool] = None,
	) -> List[Dict[str, Any]]:
		filters: Dict[str, Any] = {}
		if category_id:
			filters["category_id"] = category_id
		if brand:
			filters["brand"] = brand
		if is_electric is not None:
			filters["is_electric"] = is_electric
		bikes = self.dao.list(filters if filters else None)
		result: List[Dict[str, Any]] = []
		for bike in bikes:
			price_value = bike.get("price")
			price_number = float(price_value) if price_value is not None else 0.0
			if min_price is not None and price_number < min_price:
				continue
			if max_price is not None and price_number > max_price:
				continue
			engine_cc_value = bike.get("engine_cc")
			engine_cc = int(engine_cc_value) if engine_cc_value is not None else 0
			# If CC filters are provided, exclude EVs with null CC
			if (min_engine_cc is not None or max_engine_cc is not None) and engine_cc_value is None:
				continue
			if min_engine_cc is not None and engine_cc < min_engine_cc:
				continue
			if max_engine_cc is not None and engine_cc > max_engine_cc:
				continue
			result.append(bike)
		# Dedupe by (name, brand)
		seen = set()
		deduped: List[Dict[str, Any]] = []
		for b in result:
			key = (str(b.get("name", "")).strip().lower(), str(b.get("brand", "")).strip().lower())
			if key in seen:
				continue
			seen.add(key)
			deduped.append(b)
		# Sort by price asc, then engine_cc asc (None treated as 0)
		def _price(b: Dict[str, Any]) -> float:
			v = b.get("price")
			return float(v) if v is not None else 0.0
		def _cc(b: Dict[str, Any]) -> int:
			v = b.get("engine_cc")
			return int(v) if v is not None else 0
		return sorted(deduped, key=lambda x: (_price(x), _cc(x)))
