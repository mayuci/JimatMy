const ApiError = require('./api_error');

function getTextQuery(value, name, maxLength) {
  if (value === undefined) return null;
  if (typeof value !== 'string') {
    throw new ApiError(400, 'VALIDATION_ERROR', `${name} must be a single text value`);
  }

  const trimmed = value.trim();
  if (!trimmed || trimmed.length > maxLength) {
    throw new ApiError(
      400,
      'VALIDATION_ERROR',
      `${name} must contain between 1 and ${maxLength} characters`,
    );
  }
  return trimmed;
}

function getIntegerQuery(value, name, defaultValue, minimum, maximum) {
  if (value === undefined) return defaultValue;
  if (typeof value !== 'string' || !/^\d+$/.test(value)) {
    throw new ApiError(400, 'VALIDATION_ERROR', `${name} must be an integer`);
  }

  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed) || parsed < minimum || parsed > maximum) {
    throw new ApiError(
      400,
      'VALIDATION_ERROR',
      `${name} must be between ${minimum} and ${maximum}`,
    );
  }
  return parsed;
}

function getItemCode(value) {
  if (!/^\d+$/.test(value)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'itemCode must be a positive integer');
  }
  const itemCode = Number(value);
  if (!Number.isSafeInteger(itemCode) || itemCode <= 0) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'itemCode must be a positive integer');
  }
  return itemCode;
}

function getDateQuery(value, name) {
  if (value === undefined) return null;
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new ApiError(400, 'VALIDATION_ERROR', `${name} must use YYYY-MM-DD format`);
  }

  const date = new Date(`${value}T00:00:00Z`);
  if (Number.isNaN(date.valueOf()) || date.toISOString().slice(0, 10) !== value) {
    throw new ApiError(400, 'VALIDATION_ERROR', `${name} must be a valid date`);
  }
  return value;
}

module.exports = { getDateQuery, getIntegerQuery, getItemCode, getTextQuery };
