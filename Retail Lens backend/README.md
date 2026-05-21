# Retail Lens API

Production-oriented Express.js backend scaffold for an optical store management application.

## Stack

- Express.js + TypeScript
- PostgreSQL + Prisma ORM
- Redis + BullMQ-ready setup
- JWT auth module scaffold
- Swagger OpenAPI docs at `/api/docs`
- WebSocket gateway at `/api/v1/realtime`
- Pino structured logging

## Modules Included

- auth
- users
- customers
- employees
- job-cards
- payments
- inventory
- tasks
- finance
- reports
- settings
- notifications
- sync
- health

## Environment

Copy `.env.example` to `.env` and update values.

Required variables:

- `PORT`
- `DATABASE_URL`
- `REDIS_URL`
- `JWT_ACCESS_SECRET`
- `JWT_REFRESH_SECRET`
- `LOG_LEVEL`

Optional local development fallback:

- `SKIP_DB_CONNECT=true` to run API without a live database while scaffolding.

## Install

```bash
npm install
```

## Prisma

```bash
npm run prisma:generate
npm run prisma:migrate
npm run prisma:seed
```

## Run

```bash
# normal development
npm run start:dev

# debug mode
npm run start:debug

# production build + run
npm run build
npm run start:prod
```

## Docker

A `docker-compose.yml` is included for API + Postgres + Redis.

```bash
docker-compose up -d
```

## Available API Routes (Scaffolded)

- `POST /api/v1/job-cards/:id/payments`
- `DELETE /api/v1/job-cards/:id/items/:itemId`
- `POST /api/v1/inventory`
- `GET /api/v1/inventory`
- `PUT /api/v1/inventory/:id`
- `GET /api/v1/inventory/:id/history`
- `GET /api/v1/inventory/alerts`
- `GET /api/v1/tasks`
- `GET /api/v1/employees/:id/tasks`
- `GET /api/v1/reports/sales`
- `GET /api/v1/finances/daily-summary`
- `POST /api/v1/finances/expenses`
- `PUT /api/v1/finances/expenses/:id`
- `DELETE /api/v1/finances/expenses/:id`
- `GET /api/v1/settings/store`
- `PUT /api/v1/settings/store`
- `POST /api/v1/notifications/send`
- `POST /api/v1/sync`

## Notes

This is a proper backend scaffold with production-oriented structure and contracts. Core business logic, RBAC enforcement, queue workers, and report aggregation are intentionally left as implementation steps on top of this foundation.
