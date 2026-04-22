/**
 * Generic Base Controller for CRUD operations
 * Implements Separation of Concerns by providing reusable controller methods
 */

export class BaseController {
  constructor(model, modelName) {
    this.model = model;
    this.modelName = modelName;
  }

  /**
   * Generic create method
   */
  async create(req, res, additionalData = {}) {
    try {
      const data = { ...req.body, ...additionalData };
      
      const result = await this.model.create({
        data,
        ...this.getIncludeOptions()
      });

      res.status(201).json({
        message: `${this.modelName} created successfully`,
        data: result
      });
    } catch (error) {
      this.handleError(res, error, `creating ${this.modelName.toLowerCase()}`);
    }
  }

  /**
   * Generic find all method with pagination
   */
  async findAll(req, res, customWhere = {}) {
    try {
      const { page = 1, limit = 20, ...filters } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const where = { ...customWhere, ...this.buildFilterConditions(filters) };

      const [results, total] = await Promise.all([
        this.model.findMany({
          where,
          skip,
          take: parseInt(limit),
          orderBy: this.getDefaultOrderBy(),
          ...this.getIncludeOptions()
        }),
        this.model.count({ where })
      ]);

      res.json({
        data: results,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      });
    } catch (error) {
      this.handleError(res, error, `fetching ${this.modelName.toLowerCase()}s`);
    }
  }

  /**
   * Generic find by ID method
   */
  async findById(req, res, idField = 'id') {
    try {
      const id = req.params[idField];
      const result = await this.model.findUnique({
        where: { [this.getIdField()]: parseInt(id) },
        ...this.getIncludeOptions()
      });

      if (!result) {
        return res.status(404).json({
          message: `${this.modelName} not found`
        });
      }

      res.json({ data: result });
    } catch (error) {
      this.handleError(res, error, `fetching ${this.modelName.toLowerCase()}`);
    }
  }

  /**
   * Generic update method
   */
  async update(req, res, idField = 'id') {
    try {
      const id = req.params[idField];
      const data = req.body;

      const result = await this.model.update({
        where: { [this.getIdField()]: parseInt(id) },
        data,
        ...this.getIncludeOptions()
      });

      res.json({
        message: `${this.modelName} updated successfully`,
        data: result
      });
    } catch (error) {
      this.handleError(res, error, `updating ${this.modelName.toLowerCase()}`);
    }
  }

  /**
   * Generic delete method
   */
  async delete(req, res, idField = 'id') {
    try {
      const id = req.params[idField];
      
      await this.model.delete({
        where: { [this.getIdField()]: parseInt(id) }
      });

      res.json({
        message: `${this.modelName} deleted successfully`
      });
    } catch (error) {
      this.handleError(res, error, `deleting ${this.modelName.toLowerCase()}`);
    }
  }

  /**
   * Generic bulk update method
   */
  async bulkUpdate(req, res, whereCondition) {
    try {
      const { data } = req.body;
      
      const result = await this.model.updateMany({
        where: whereCondition,
        data
      });

      res.json({
        message: `${this.modelName}s updated successfully`,
        count: result.count
      });
    } catch (error) {
      this.handleError(res, error, `bulk updating ${this.modelName.toLowerCase()}s`);
    }
  }

  /**
   * Helper methods to be overridden by subclasses
   */
  getIdField() {
    return `${this.modelName.toLowerCase()}Id`;
  }

  getDefaultOrderBy() {
    return { createdAt: 'desc' };
  }

  getIncludeOptions() {
    return {};
  }

  buildFilterConditions(filters) {
    const conditions = {};
    for (const [key, value] of Object.entries(filters)) {
      if (value !== undefined && value !== null && value !== '') {
        conditions[key] = value;
      }
    }
    return conditions;
  }

  handleError(res, error, action) {
    console.error(`${this.modelName} ${action} error:`, error);
    
    if (error.code === 'P2025') {
      return res.status(404).json({ 
        message: `${this.modelName} not found` 
      });
    }
    
    if (error.code === 'P2002') {
      return res.status(400).json({ 
        message: 'Record already exists' 
      });
    }

    res.status(500).json({ 
      message: `Error ${action}: ${error.message || 'Internal server error'}` 
    });
  }
}

/**
 * Generic Service Layer for business logic
 */
export class BaseService {
  constructor(controller) {
    this.controller = controller;
  }

  /**
   * Generic validation method
   */
  validateData(data, requiredFields = []) {
    const errors = [];
    
    requiredFields.forEach(field => {
      if (!data[field] || data[field].toString().trim() === '') {
        errors.push(`${field} is required`);
      }
    });

    return errors;
  }

  /**
   * Generic authorization check
   */
  async checkAuthorization(userId, resourceId, permission) {
    // Implement authorization logic here
    return true;
  }

  /**
   * Generic data transformation
   */
  transformData(data, transformations = {}) {
    const transformed = { ...data };
    
    Object.keys(transformations).forEach(key => {
      if (transformed[key] !== undefined) {
        transformed[key] = transformations[key](transformed[key]);
      }
    });

    return transformed;
  }
}