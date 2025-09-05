# Clay Community Site

ねんど制作のためのコミュニティサイト - A community platform for clay artists to share their work, learn techniques, and connect with other creators.

## Features

- User authentication and profiles
- Image upload and sharing
- Social interactions (likes, comments, follows)
- Tutorial system for learning clay techniques
- Content moderation system
- Mobile-responsive design
- RESTful API for external access

## Tech Stack

- **Backend**: Ruby on Rails 8.0
- **Database**: PostgreSQL 15
- **Cache/Jobs**: Redis 7 + Sidekiq
- **File Storage**: Google Cloud Storage (production), Local (development)
- **Containerization**: Docker & Docker Compose
- **Deployment**: Google Cloud Run
- **CI/CD**: GitHub Actions

## Prerequisites

- Docker and Docker Compose
- Git

## Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd clay_community_site
   ```

2. **Copy environment configuration**
   ```bash
   cp .env.example .env.development
   ```

3. **Build and start services**
   ```bash
   docker-compose up --build
   ```

4. **Setup database** (in another terminal)
   ```bash
   docker-compose exec web rails db:create db:migrate db:seed
   ```

5. **Access the application**
   - Web: http://localhost:3000
   - Sidekiq Web UI: http://localhost:3000/sidekiq (in development)

## Local Development (without Docker)

1. **Install dependencies**
   ```bash
   docker compose exec web bundle install
   ```

2. **Setup database**
   ```bash
   docker compose exec web bin/rails db:create db:migrate db:seed
   ```

3. **Start services**
   ```bash
   # Terminal 1: Rails server
   rails server

   # Terminal 2: Sidekiq (background jobs)
   bundle exec sidekiq

   # Terminal 3: Redis (if not using Docker)
   redis-server
   ```

## Testing

```bash
# Run all tests
docker-compose exec web rspec

# Run specific test file
docker-compose exec web rspec spec/models/user_spec.rb

# Run with coverage
docker-compose exec web rspec --format documentation
```

## API Documentation

The application provides a RESTful API for external access. Key endpoints:

- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `GET /api/v1/posts` - List posts with pagination
- `POST /api/v1/posts` - Create new post
- `GET /api/v1/posts/:id` - Get specific post
- `POST /api/v1/posts/:id/like` - Like/unlike post
- `POST /api/v1/posts/:id/comments` - Add comment

## Deployment

The application is configured for deployment on Google Cloud Platform using:

- **Google Cloud Run** for container hosting
- **Google Cloud SQL** for PostgreSQL database
- **Google Cloud Storage** for file storage
- **Google Cloud CDN** for content delivery

See `.github/workflows/deploy.yml` for CI/CD configuration.

## Environment Variables

Key environment variables (see `.env.example` for complete list):

- `DATABASE_HOST` - Database host
- `DATABASE_USERNAME` - Database username
- `DATABASE_PASSWORD` - Database password
- `REDIS_URL` - Redis connection URL
- `GCS_BUCKET` - Google Cloud Storage bucket name
- `GOOGLE_CLOUD_PROJECT` - GCP project ID

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
