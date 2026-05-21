import request from 'supertest';
import { createApp } from '../src/app';

describe('Express API (e2e)', () => {
  it('/api/v1/health (GET)', async () => {
    const app = createApp();

    await request(app).get('/api/v1/health').expect(200);
  });
});
