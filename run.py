import os
import sys

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.join(CURRENT_DIR, "src")
if SRC_DIR not in sys.path:
	sys.path.insert(0, SRC_DIR)

from cli.main import main

if __name__ == "__main__":
	main()
