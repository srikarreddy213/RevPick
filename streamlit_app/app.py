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
		key: Optional[str] = st.secrets.get("SUPABASE_ANON_KEY") or st.secrets.get("SUPABASE_KEY")
		if not url or not key:
			st.info("Add SUPABASE_URL and SUPABASE_ANON_KEY (or SUPABASE_KEY) to .streamlit/secrets.toml to enable live data.")
			return None
		return create_client(url, key)
	except Exception as exc:
		st.warning(f"Supabase SDK not available or misconfigured: {exc}")
		return None


supabase = init_connection()


def view_products():
	st.header("Find Bikes")

	with st.form("finder_form", clear_on_submit=False):
		col1, col2, col3 = st.columns(3)
		with col1:
			type_choice = st.selectbox("Type", ["Any", "ICE", "EV"], index=0)
		with col2:
			min_price = st.number_input("Min price", min_value=0, value=0, step=1000)
		with col3:
			max_price = st.number_input("Max price", min_value=0, value=0, step=1000)

		col4, col5 = st.columns(2)
		with col4:
			min_cc = st.number_input("Min CC (ICE)", min_value=0, value=0, step=50)
		with col5:
			max_cc = st.number_input("Max CC (ICE)", min_value=0, value=0, step=50)

		submitted = st.form_submit_button("Search")

	if not submitted:
		st.info("Set your filters and press Search.")
		return

	if not supabase:
		st.warning("Live data unavailable. Configure Supabase secrets to fetch results.")
		st.dataframe([], use_container_width=True)
		return

	results = []

	# Price filters helper
	def apply_price_filters(q):
		if min_price and min_price > 0:
			q = q.gte("price", min_price)
		if max_price and max_price > 0:
			q = q.lte("price", max_price)
		return q

	try:
		if type_choice in ("Any", "ICE"):
			q_ice = supabase.table("products").select("*").eq("is_electric", False)
			if min_cc and min_cc > 0:
				q_ice = q_ice.gte("engine_cc", min_cc)
			if max_cc and max_cc > 0:
				q_ice = q_ice.lte("engine_cc", max_cc)
			q_ice = apply_price_filters(q_ice)
			ice_resp = q_ice.order("price").execute()
			results.extend(ice_resp.data or [])

		if type_choice in ("Any", "EV"):
			q_ev = supabase.table("products").select("*").eq("is_electric", True)
			q_ev = apply_price_filters(q_ev)
			ev_resp = q_ev.order("price").execute()
			results.extend(ev_resp.data or [])

		# Deduplicate by prod_id when present, otherwise by (brand,name,engine_cc,power_kw,price)
		seen = set()
		unique_results = []
		for r in results:
			if r.get("prod_id"):
				key = ("id", r.get("prod_id"))
			else:
				key = ("spec", r.get("brand"), r.get("name"), r.get("engine_cc"), r.get("power_kw"), r.get("price"))
			if key in seen:
				continue
			seen.add(key)
			unique_results.append(r)

		# Filter out columns not needed: prod_id, created_at, is_electric
		display = []
		for r in unique_results:
			pruned = {k: v for k, v in r.items() if k not in {"prod_id", "created_at", "is_electric"}}
			display.append(pruned)
		st.success(f"Found {len(display)} unique bikes")
		st.dataframe(display, use_container_width=True)
	except Exception as e:
		st.error(f"Search failed: {e}")


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


def main():
	view_products()


if __name__ == "__main__":
	main()


