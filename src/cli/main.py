from typing import Optional

from services.product_service import ProductService
from services.suggestion_service import SuggestionService
from utils.helpers import prompt_float, prompt_int, prompt_str
from config.supabase_config import get_client


product_service = ProductService()
suggestion_service = SuggestionService()


def _format_table(headers, rows):
	# Compute column widths
	widths = [len(h) for h in headers]
	for r in rows:
		for i, cell in enumerate(r):
			w = len(str(cell))
			if w > widths[i]:
				widths[i] = w
	# Build format string
	parts = ["{:<" + str(w) + "}" for w in widths]
	fmt = "  ".join(parts)
	# Print header
	print(fmt.format(*headers))
	print("  ".join(["-" * w for w in widths]))
	# Print rows
	for r in rows:
		print(fmt.format(*[str(c) for c in r]))



def view_bike_suggestions() -> None:
	min_budget = prompt_float("Min Budget [blank=any]:", None)
	max_budget = prompt_float("Max Budget [blank=any]:", None)
	min_cc = prompt_int("Min Engine CC [blank=any]:", None)
	max_cc = prompt_int("Max Engine CC [blank=any]:", None)
	brand = prompt_str("Preferred Brand [blank=any]:", None)
	location = prompt_str("Location/City [blank=any]:", None)
	bikes = suggestion_service.suggest_bikes(
		cust_id=None,
		budget=max_budget,
		min_budget=min_budget,
		min_cc=min_cc,
		max_cc=max_cc,
		brand=brand or None,
		category_id=None,
		location=location or None,
		is_electric=False,
	)
	if not bikes:
		print("No bikes matched your preferences.")
		return
	print("\nSuggestions:")
	headers = ["#", "Name", "Brand", "CC", "BHP", "Torque(Nm)", "Mileage", "Price(₹)", "Stock"]
	rows = []
	for idx, b in enumerate(bikes, start=1):
		cc = f"{b.get('engine_cc')}" if b.get('engine_cc') is not None else "-"
		bhp = b.get('bhp') if b.get('bhp') is not None else "-"
		torque = b.get('torque_nm') if b.get('torque_nm') is not None else "-"
		mileage = b.get('mileage_kmpl') if b.get('mileage_kmpl') is not None else "-"
		price = b.get('price') if b.get('price') is not None else "-"
		stock = b.get('stock') if b.get('stock') is not None else "-"
		rows.append([idx, b.get('name'), b.get('brand'), cc, bhp, torque, mileage, price, stock])
	_format_table(headers, rows)
def view_electric_bikes() -> None:
	min_budget = prompt_float("Min Budget [blank=any]:", None)
	max_budget = prompt_float("Max Budget [blank=any]:", None)
	brand = prompt_str("Preferred Brand [blank=any]:", None)
	bikes = suggestion_service.suggest_bikes(
		cust_id=None,
		budget=max_budget,
		min_budget=min_budget,
		min_cc=None,
		max_cc=None,
		brand=brand or None,
		category_id=None,
		location=None,
		is_electric=True,
	)
	if not bikes:
		print("No electric bikes matched your preferences.")
		return
	print("\nElectric Bikes:")
	headers = ["#", "Name", "Brand", "Power(kW)", "Mileage", "Price(₹)", "Stock"]
	rows = []
	for idx, b in enumerate(bikes, start=1):
		kw = b.get('power_kw') if b.get('power_kw') is not None else "-"
		mileage = b.get('mileage_kmpl') if b.get('mileage_kmpl') is not None else "-"
		price = b.get('price') if b.get('price') is not None else "-"
		stock = b.get('stock') if b.get('stock') is not None else "-"
		rows.append([idx, b.get('name'), b.get('brand'), kw, mileage, price, stock])
	_format_table(headers, rows)




def add_update_bike() -> None:
	prod_id = prompt_str("Existing Product ID to update [leave blank to create]:", None)
	name = prompt_str("Name:")
	engine_cc = prompt_int("Engine CC:")
	price = prompt_float("Price:")
	stock = prompt_int("Stock:", 0)
	brand = prompt_str("Brand:")
	category_id = prompt_str("Category ID (UUID) [blank=none]:", None)
	data = {
		"prod_id": prod_id,
		"name": name,
		"engine_cc": engine_cc,
		"price": price,
		"stock": stock,
		"brand": brand,
	}
	# Clean empty string UUIDs which cause 400 errors
	if not data.get("prod_id"):
		data.pop("prod_id", None)
	if category_id and category_id.strip():
		data["category_id"] = category_id.strip()
	result = product_service.add_or_update_bike(data)
	if not result:
		print("No changes made.")
		return
	print("Saved:")
	print(f"- prod_id: {result.get('prod_id')}")
	print(f"- name: {result.get('name')}")
	print(f"- engine_cc: {result.get('engine_cc')}")
	print(f"- price: {result.get('price')}")
	print(f"- stock: {result.get('stock')}")
	print(f"- brand: {result.get('brand')}")
	print(f"- category_id: {result.get('category_id')}")




def main() -> None:
	while True:
		print("\nRevPick - Bike Suggestion System")
		print("1. View Bike Suggestions (by CC, budget, location)")
		print("2. Add/Update Bike (store manager)")
		print("3. View Electric Bikes (by budget, brand)")
		print("4. Exit")
		choice = input("Choose an option (1-4): ")
		if choice == "1":
			view_bike_suggestions()
		elif choice == "2":
			add_update_bike()
		elif choice == "3":
			view_electric_bikes()
		elif choice == "4":
			print("Goodbye!")
			break
		else:
			print("Invalid option. Please choose 1-4.")


if __name__ == "__main__":
	main()
