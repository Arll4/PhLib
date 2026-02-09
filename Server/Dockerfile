FROM python:3.11-slim

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy server files
COPY . .

# Expose the API port
EXPOSE 8000

# Initialize database and run the server
CMD ["sh", "-c", "python -c 'import db; db.init_db()' && python app.py"]
