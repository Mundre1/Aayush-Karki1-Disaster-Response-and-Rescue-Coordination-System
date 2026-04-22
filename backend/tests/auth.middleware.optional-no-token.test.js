import { jest } from '@jest/globals';
import { optionalAuthenticateToken } from '../src/middleware/auth.middleware.js';

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

test('UT-JS-04 optionalAuthenticateToken calls next when no token is provided', () => {
  const req = { headers: {} };
  const res = createRes();
  const next = jest.fn();

  optionalAuthenticateToken(req, res, next);

  expect(next).toHaveBeenCalledTimes(1);
  expect(req.user).toBeUndefined();
  expect(res.statusCode).toBeNull();
});
