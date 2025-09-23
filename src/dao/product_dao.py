from typing import Any, Dict, List, Optional


class ProductDAO:
	TABLE = "products"

	def __init__(self, client) -> None:
		self.client = client

	def create(self, data: Dict[str, Any]) -> Dict[str, Any]:
		response = self.client.table(self.TABLE).insert(data).execute()
		return response.data[0] if response.data else {}

	def get_by_id(self, prod_id: str) -> Optional[Dict[str, Any]]:
		response = (
			self.client.table(self.TABLE).select("*").eq("prod_id", prod_id).limit(1).execute()
		)
		return response.data[0] if response.data else None

	def update(self, prod_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
		response = (
			self.client.table(self.TABLE).update(updates).eq("prod_id", prod_id).execute()
		)
		return response.data[0] if response.data else None

	def delete(self, prod_id: str) -> int:
		response = self.client.table(self.TABLE).delete().eq("prod_id", prod_id).execute()
		return len(response.data) if response.data else 0

	def list(self, filters: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
		query = self.client.table(self.TABLE).select("*")
		if filters:
			for key, value in filters.items():
				query = query.eq(key, value)
		return query.execute().data or []
