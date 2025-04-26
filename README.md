# Moc-production-be
Backend for Moc production version 2025

## How to Run

### Running with Docker

1. **Create a `.env` file from the example**:
   ```bash
   cp .env.example .env
   ```
2. **Build the container**:
   ```bash
   docker-compose build
   ```
3. **Run the container**:
   ```bash
   docker-compose up
   ```
4. **Access the application**:
    The application will run on `http://localhost:APP_PORT/swagger`, where `APP_PORT` is defined in your `.env` file. 
    Basic Auth config in your `.env` file: 
    - **Username**: `SWAGGER_USER`
    - **Password**: `SWAGGER_PASSWORD`
