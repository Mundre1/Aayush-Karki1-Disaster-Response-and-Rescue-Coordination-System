import jwt from 'jsonwebtoken';
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

afterEach(() => {
  jest.restoreAllMocks();
});

test('UT-JS-02 authenticateToken returns 403 when token verification fails', () => {
  const req = { headers: { authorization: 'Bearer bad.token' } };
  const res = createRes();
  const next = jest.fn();
  jest.spyOn(jwt, 'verify').mockImplementation((_token, _secret, callback) => {
    callback(new Error('invalid token'));
  });

  authenticateToken(req, res, next);

  expect(res.statusCode).toBe(403);
  expect(res.payload).toEqual({ message: 'Invalid or expired token' });
  expect(next).not.toHaveBeenCalled();
});
