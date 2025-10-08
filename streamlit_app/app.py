import os
from datetime import datetime

import streamlit as st


st.set_page_config(page_title="RevPick", page_icon="🏍️", layout="wide")


def init_connection():
	"""Initialize Supabase client from st.secrets; placeholder until configured."""
	from typing import Optional
	try:
		# Lazy import to avoid hard dependency if user hasn't installed yet
		from supabase import create_client, Client
		url: Optional[str] = st.secrets.get("SUPABASE_URL")
		key: Optional[str] = st.secrets.get("SUPABASE_ANON_KEY")
		if not url or not key:
			st.info("Add SUPABASE_URL and SUPABASE_ANON_KEY to .streamlit/secrets.toml to enable live data.")
			return None
		return create_client(url, key)
	except Exception as exc:
		st.warning(f"Supabase SDK not available or misconfigured: {exc}")
		return None


supabase = init_connection()


def view_products():
	st.header("Products")
	col_filters = st.columns(4)
	with col_filters[0]:
		brand_filter = st.text_input("Brand contains")
	with col_filters[1]:
		name_filter = st.text_input("Name contains")
	with col_filters[2]:
		is_ev = st.selectbox("Type", ["Any", "ICE", "EV"])
	with col_filters[3]:
		max_price = st.number_input("Max price", min_value=0, value=0)

	if supabase:
		query = supabase.table("products").select("*")
		if brand_filter:
			query = query.ilike("brand", f"%{brand_filter}%")
		if name_filter:
			query = query.ilike("name", f"%{name_filter}%")
		if is_ev == "EV":
			query = query.eq("is_electric", True)
		elif is_ev == "ICE":
			query = query.eq("is_electric", False)
		if max_price and max_price > 0:
			query = query.lte("price", max_price)
		resp = query.order("created_at", desc=True).execute()
		data = resp.data or []
		st.dataframe(data, use_container_width=True)
	else:
		st.info("Live data unavailable. Showing sample columns.")
		st.dataframe([
			{"name": "Sample Bike", "brand": "BrandX", "price": 100000, "is_electric": False},
		])

	with st.expander("Add new product"):
		with st.form("add_product_form"):
			name = st.text_input("Name")
			brand = st.text_input("Brand")
			is_electric = st.checkbox("Electric (EV)")
			engine_cc = None
			power_kw = None
			if is_electric:
				power_kw = st.number_input("Power (kW)", min_value=0.0, step=0.1)
			else:
				engine_cc = st.number_input("Engine CC", min_value=1, step=1)
			price = st.number_input("Price", min_value=0, step=1000)
			stock = st.number_input("Stock", min_value=0, step=1)
			category_id = st.text_input("Category ID (optional)")
			submitted = st.form_submit_button("Create")
			if submitted:
				if not supabase:
					st.error("Configure Supabase to insert.")
				else:
					payload = {
						"name": name,
						"brand": brand,
						"price": price,
						"stock": stock,
						"category_id": category_id or None,
						"is_electric": bool(is_electric),
						"engine_cc": int(engine_cc) if not is_electric and engine_cc else None,
						"power_kw": float(power_kw) if is_electric and power_kw is not None else None,
					}
					try:
						res = supabase.table("products").insert(payload).execute()
						if res.data:
							st.success("Product created.")
							st.experimental_rerun()
						else:
							st.warning("No data returned.")
					except Exception as e:
						st.error(f"Insert failed: {e}")


def view_customers():
	st.header("Customers")
	if supabase:
		resp = supabase.table("customers").select("*").order("created_at", desc=True).execute()
		st.dataframe(resp.data or [], use_container_width=True)
	else:
		st.dataframe([{"name": "Alice", "email": "alice@example.com", "city": "Pune"}], use_container_width=True)

	with st.expander("Add customer"):
		with st.form("add_customer_form"):
			name = st.text_input("Name")
			email = st.text_input("Email")
			phone = st.text_input("Phone")
			city = st.text_input("City")
			submitted = st.form_submit_button("Create")
			if submitted:
				if not supabase:
					st.error("Configure Supabase to insert.")
				else:
					payload = {"name": name, "email": email or None, "phone": phone or None, "city": city or None}
					try:
						res = supabase.table("customers").insert(payload).execute()
						if res.data:
							st.success("Customer created.")
							st.experimental_rerun()
						else:
							st.warning("No data returned.")
					except Exception as e:
						st.error(f"Insert failed: {e}")


def view_suggestions():
	st.header("Suggestions")
	if supabase:
		customers = (supabase.table("customers").select("cust_id,name").order("name").execute().data or [])
		products = (supabase.table("products").select("prod_id,name,brand").order("brand").execute().data or [])
		cust_name_to_id = {f"{c['name']}": c["cust_id"] for c in customers}
		prod_name_to_id = {f"{p['brand']} - {p['name']}": p["prod_id"] for p in products}
	else:
		cust_name_to_id = {"Alice": "demo-cust"}
		prod_name_to_id = {"BrandX - Sample Bike": "demo-prod"}

	with st.form("add_suggestion_form"):
		cust_choice = st.selectbox("Customer", list(cust_name_to_id.keys()))
		prod_choice = st.selectbox("Product", list(prod_name_to_id.keys()))
		submitted = st.form_submit_button("Log suggestion")
		if submitted:
			if not supabase:
				st.error("Configure Supabase to insert.")
			else:
				payload = {"cust_id": cust_name_to_id[cust_choice], "prod_id": prod_name_to_id[prod_choice]}
				try:
					res = supabase.table("suggestions").insert(payload).execute()
					if res.data:
						st.success("Suggestion logged.")
						st.experimental_rerun()
					else:
						st.warning("No data returned.")
				except Exception as e:
					st.error(f"Insert failed: {e}")

	if supabase:
		resp = supabase.table("suggestions").select("*, customers(name), products(name,brand)").order("date_requested", desc=True).execute()
		rows = resp.data or []
		for r in rows:
			st.write(
				f"{r.get('date_requested', '')}: Suggested {r.get('products', {}).get('brand', '')} {r.get('products', {}).get('name', '')} to {r.get('customers', {}).get('name', '')}"
			)


PAGES = {
	"Products": view_products,
	"Customers": view_customers,
	"Suggestions": view_suggestions,
}


def main():
	st.sidebar.title("RevPick")
	page = st.sidebar.radio("Go to", list(PAGES.keys()))
	PAGES[page]()


if __name__ == "__main__":
	main()


