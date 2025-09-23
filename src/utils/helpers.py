from typing import Optional


def prompt_int(message: str, default: Optional[int] = None) -> Optional[int]:
	try:
		value = input(f"{message} ")
		if value.strip() == "" and default is not None:
			return default
		return int(value)
	except (ValueError, KeyboardInterrupt):
		return default


def prompt_float(message: str, default: Optional[float] = None) -> Optional[float]:
	try:
		value = input(f"{message} ")
		if value.strip() == "" and default is not None:
			return default
		return float(value)
	except (ValueError, KeyboardInterrupt):
		return default


def prompt_str(message: str, default: Optional[str] = None) -> Optional[str]:
	try:
		value = input(f"{message} ")
		if value.strip() == "" and default is not None:
			return default
		return value
	except KeyboardInterrupt:
		return default
