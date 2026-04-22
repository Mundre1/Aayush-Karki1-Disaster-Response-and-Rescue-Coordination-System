import { jest } from '@jest/globals';
import { authenticateToken } from '../src/middleware/auth.middleware.js';

function createRes() {
  return {
    statusCode: null,
    payload: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.payload = body;
      return this;
    },
  };
}

test('UT-JS-01 authenticateToken returns 401 when bearer token is missing', () => {
  const req = { headers: {} };
  const res = createRes();
  const next = jest.fn();

  authenticateToken(req, res, next);

  expect(res.statusCode).toBe(401);
  expect(res.payload).toEqual({ message: 'Access token required' });
  expect(next).not.toHaveBeenCalled();
});
