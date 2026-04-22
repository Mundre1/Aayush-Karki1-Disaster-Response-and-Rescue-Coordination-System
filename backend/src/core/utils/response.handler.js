/**
 * Generic Response Handler for consistent API responses
 * Implements Separation of Concerns by centralizing response formatting
 */

export class ApiResponse {
  static success(res, data = null, message = 'Success', statusCode = 200) {
    return res.status(statusCode).json({
      success: true,
      message,
      data,
      timestamp: new Date().toISOString()
    });
  }

  static created(res, data, message = 'Resource created successfully') {
    return this.success(res, data, message, 201);
  }

  static noContent(res, message = 'No content') {
    return res.status(204).json({
      success: true,
      message,
      timestamp: new Date().toISOString()
    });
  }

  static error(res, message = 'Internal server error', statusCode = 500, errorDetails = null) {
    const response = {
      success: false,
      message,
      timestamp: new Date().toISOString()
    };

    if (errorDetails) {
      response.details = errorDetails;
    }

    return res.status(statusCode).json(response);
  }

  static badRequest(res, message = 'Bad request', errors = null) {
    return this.error(res, message, 400, errors);
  }

  static unauthorized(res, message = 'Unauthorized') {
    return this.error(res, message, 401);
  }

  static forbidden(res, message = 'Forbidden') {
    return this.error(res, message, 403);
  }

  static notFound(res, message = 'Resource not found') {
    return this.error(res, message, 404);
  }

  static conflict(res, message = 'Conflict') {
    return this.error(res, message, 409);
  }

  static validationError(res, errors) {
    return this.badRequest(res, 'Validation failed', errors);
  }

  static paginated(res, data, pagination, message = 'Success') {
    return res.status(200).json({
      success: true,
      message,
      data,
      pagination,
      timestamp: new Date().toISOString()
    });
  }

  static withMeta(res, data, meta, message = 'Success') {
    return res.status(200).json({
      success: true,
      message,
      data,
      meta,
      timestamp: new Date().toISOString()
    });
  }
}

/**
 * Generic Error Handler
 */
export class ErrorHandler {
  static handlePrismaError(error) {
    switch (error.code) {
      case 'P2002':
        return {
          message: 'Record already exists',
          statusCode: 409,
          details: error.meta?.target || 'Duplicate entry'
        };
      case 'P2025':
        return {
          message: 'Record not found',
          statusCode: 404
        };
      case 'P2003':
        return {
          message: 'Foreign key constraint failed',
          statusCode: 400,
          details: error.meta?.field_name
        };
      default:
        return {
          message: 'Database error occurred',
          statusCode: 500,
          details: error.message
        };
    }
  }

  static handleValidationError(errors) {
    return {
      message: 'Validation failed',
      statusCode: 400,
      details: errors
    };
  }

  static handleGenericError(error) {
    return {
      message: error.message || 'Internal server error',
      statusCode: 500,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    };
  }
}

/**
 * Generic Validation Helper
 */
export class ValidationHelper {
  static required(value, fieldName) {
    if (!value || value.toString().trim() === '') {
      return `${fieldName} is required`;
    }
    return null;
  }

  static minLength(value, min, fieldName) {
    if (value && value.toString().length < min) {
      return `${fieldName} must be at least ${min} characters`;
    }
    return null;
  }

  static maxLength(value, max, fieldName) {
    if (value && value.toString().length > max) {
      return `${fieldName} must not exceed ${max} characters`;
    }
    return null;
  }

  static email(value, fieldName) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (value && !emailRegex.test(value)) {
      return `${fieldName} must be a valid email address`;
    }
    return null;
  }

  static numeric(value, fieldName) {
    if (value && isNaN(value)) {
      return `${fieldName} must be a number`;
    }
    return null;
  }

  static enum(value, validValues, fieldName) {
    if (value && !validValues.includes(value)) {
      return `${fieldName} must be one of: ${validValues.join(', ')}`;
    }
    return null;
  }

  static validate(data, rules) {
    const errors = [];

    Object.keys(rules).forEach(fieldName => {
      const fieldRules = rules[fieldName];
      const value = data[fieldName];

      fieldRules.forEach(rule => {
        const error = rule(value, fieldName);
        if (error) {
          errors.push(error);
        }
      });
    });

    return errors.length > 0 ? errors : null;
  }
}