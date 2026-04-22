import jwt from 'jsonwebtoken';
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

afterEach(() => {
  jest.restoreAllMocks();
});

test('UT-JS-05 optionalAuthenticateToken stores user when token is valid', () => {
  const req = { headers: { authorization: 'Bearer optional.good' } };
  const res = createRes();
  const next = jest.fn();
  const decoded = { userId: 11, roleId: 2 };

  jest.spyOn(jwt, 'verify').mockImplementation((_token, _secret, callback) => {
    callback(null, decoded);
  });

  optionalAuthenticateToken(req, res, next);

  expect(req.user).toEqual(decoded);
  expect(next).toHaveBeenCalledTimes(1);
  expect(res.statusCode).toBeNull();
});
