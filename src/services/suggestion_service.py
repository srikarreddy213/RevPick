from datetime import datetime
from typing import Any, Dict, List, Optional

from config.supabase_config import get_client
from dao.suggestion_dao import SuggestionDAO
from services.product_service import ProductService


class SuggestionService:
	def __init__(self) -> None:
		self.dao = SuggestionDAO(get_client())
		self.product_service = ProductService()

	def suggest_bikes(
		self,
		cust_id: Optional[str] = None,
		budget: Optional[float] = None,
		min_budget: Optional[float] = None,
		min_cc: Optional[int] = None,
		max_cc: Optional[int] = None,
		brand: Optional[str] = None,
		category_id: Optional[str] = None,
		location: Optional[str] = None,
		is_electric: Optional[bool] = None,
	) -> List[Dict[str, Any]]:
		bikes = self.product_service.list_bikes(
			category_id=category_id,
			brand=brand,
			min_price=min_budget,
			max_price=budget,
			min_engine_cc=min_cc,
			max_engine_cc=max_cc,
			location=location,
			is_electric=is_electric,
		)
		if cust_id:
			for bike in bikes[:5]:
				self.dao.create(
					{
						"cust_id": cust_id,
						"prod_id": bike.get("prod_id"),
						"date_requested": datetime.utcnow().isoformat(),
					}
				)
		return bikes

	def generate_report(self) -> Dict[str, Any]:
		client = get_client()
		products_count = len(client.table("products").select("prod_id").execute().data or [])
		customers_count = len(client.table("customers").select("cust_id").execute().data or [])
		suggestions_count = len(client.table("suggestions").select("suggestion_id").execute().data or [])
		return {
			"products": products_count,
			"customers": customers_count,
			"suggestions": suggestions_count,
		}
