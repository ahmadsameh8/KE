Three commands to verify everything works
From your project root:

# 1. Database connection works
uv run python -m src.db

# 2. LLM chain answers a question
uv run python -m src.chain

# 3. Streamlit app launches
uv run streamlit run app/chat.py