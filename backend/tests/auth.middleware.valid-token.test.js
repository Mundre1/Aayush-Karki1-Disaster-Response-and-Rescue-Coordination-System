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

test('UT-JS-03 authenticateToken attaches decoded user and calls next on success', () => {
  const req = { headers: { authorization: 'Bearer good.token' } };
  const res = createRes();
  const next = jest.fn();
  const decoded = { userId: 5, roleId: 1 };

  jest.spyOn(jwt, 'verify').mockImplementation((_token, _secret, callback) => {
    callback(null, decoded);
  });

  authenticateToken(req, res, next);

  expect(req.user).toEqual(decoded);
  expect(next).toHaveBeenCalledTimes(1);
  expect(res.statusCode).toBeNull();
});
