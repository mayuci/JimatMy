const ApiError = require('./api_error');

function getBody(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Request body must be a JSON object');
  }
  return value;
}

function rejectUnknownFields(body, allowed) {
  const unknown = Object.keys(body).filter((key) => !allowed.includes(key));
  if (unknown.length) {
    throw new ApiError(
      400,
      'VALIDATION_ERROR',
      `Unsupported field${unknown.length > 1 ? 's' : ''}: ${unknown.join(', ')}`,
    );
  }
}

function getUuid(value, name) {
  if (
    typeof value !== 'string' ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
  ) {
    throw new ApiError(400, 'VALIDATION_ERROR', `${name} must be a valid UUID`);
  }
  return value;
}

function getName(value) {
  if (typeof value !== 'string') {
    throw new ApiError(400, 'VALIDATION_ERROR', 'name must be text');
  }
  const name = value.trim();
  if (!name || name.length > 100) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'name must contain 1 to 100 characters');
  }
  return name;
}

function getItemCode(value) {
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'itemCode must be a positive integer');
  }
  return value;
}

function getPositiveDecimal(value, name, maximum) {
  if (
    typeof value !== 'number' ||
    !Number.isFinite(value) ||
    value <= 0 ||
    value > maximum ||
    !/^\d+(?:\.\d{1,2})?$/.test(String(value))
  ) {
    throw new ApiError(
      400,
      'VALIDATION_ERROR',
      `${name} must be a positive number with at most 2 decimal places`,
    );
  }
  return value;
}

function getBoolean(value, name) {
  if (typeof value !== 'boolean') {
    throw new ApiError(400, 'VALIDATION_ERROR', `${name} must be a boolean`);
  }
  return value;
}

function getBestPlacesQuery(query) {
  const value = query && typeof query === 'object' ? query : {};
  rejectUnknownFields(value, [
    'coverage',
    'sort',
    'state',
    'district',
    'maxTotal',
    'latitude',
    'longitude',
    'radiusKm',
    'page',
    'limit',
  ]);

  const getSingle = (name) => {
    const entry = value[name];
    if (Array.isArray(entry)) {
      throw new ApiError(400, 'VALIDATION_ERROR', `${name} must be provided once`);
    }
    return entry;
  };
  const getChoice = (name, allowed, fallback) => {
    const entry = getSingle(name);
    if (entry === undefined) return fallback;
    if (typeof entry !== 'string' || !allowed.includes(entry)) {
      throw new ApiError(
        400,
        'VALIDATION_ERROR',
        `${name} must be one of: ${allowed.join(', ')}`,
      );
    }
    return entry;
  };
  const getOptionalText = (name) => {
    const entry = getSingle(name);
    if (entry === undefined) return null;
    if (typeof entry !== 'string') {
      throw new ApiError(400, 'VALIDATION_ERROR', `${name} must be text`);
    }
    const text = entry.trim();
    if (!text || text.length > 100) {
      throw new ApiError(
        400,
        'VALIDATION_ERROR',
        `${name} must contain 1 to 100 characters`,
      );
    }
    return text;
  };
  const getPositiveInteger = (name, fallback, maximum) => {
    const entry = getSingle(name);
    if (entry === undefined) return fallback;
    if (typeof entry !== 'string' || !/^\d+$/.test(entry)) {
      throw new ApiError(400, 'VALIDATION_ERROR', `${name} must be a positive integer`);
    }
    const number = Number(entry);
    if (!Number.isSafeInteger(number) || number < 1 || number > maximum) {
      throw new ApiError(
        400,
        'VALIDATION_ERROR',
        `${name} must be between 1 and ${maximum}`,
      );
    }
    return number;
  };

  const maxTotalValue = getSingle('maxTotal');
  let maxTotal = null;
  if (maxTotalValue !== undefined) {
    if (
      typeof maxTotalValue !== 'string' ||
      !/^\d+(?:\.\d{1,2})?$/.test(maxTotalValue) ||
      Number(maxTotalValue) <= 0 ||
      Number(maxTotalValue) > 99999999.99
    ) {
      throw new ApiError(
        400,
        'VALIDATION_ERROR',
        'maxTotal must be a positive RM amount with at most 2 decimal places',
      );
    }
    maxTotal = Number(maxTotalValue);
  }

  const parseCoordinate = (name, minimum, maximum) => {
    const entry = getSingle(name);
    if (entry === undefined) return null;
    if (typeof entry !== 'string' || entry.trim() === '') {
      throw new ApiError(400, 'VALIDATION_ERROR', `${name} must be a valid coordinate`);
    }
    const number = Number(entry);
    if (!Number.isFinite(number) || number < minimum || number > maximum) {
      throw new ApiError(400, 'VALIDATION_ERROR', `${name} is outside Malaysia`);
    }
    return number;
  };
  const latitude = parseCoordinate('latitude', 0.5, 7.5);
  const longitude = parseCoordinate('longitude', 99, 120.5);
  if ((latitude === null) !== (longitude === null)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'latitude and longitude must be provided together');
  }
  const radiusValue = getSingle('radiusKm');
  let radiusKm = null;
  if (radiusValue !== undefined) {
    if (latitude === null || typeof radiusValue !== 'string' || !['10', '25', '50'].includes(radiusValue)) {
      throw new ApiError(
        400,
        'VALIDATION_ERROR',
        'radiusKm must be 10, 25, or 50 and requires latitude and longitude',
      );
    }
    radiusKm = Number(radiusValue);
  }

  return {
    coverage: getChoice('coverage', ['all', 'complete', 'incomplete'], 'all'),
    sort: getChoice('sort', ['price_asc', 'price_desc', 'coverage'], 'price_asc'),
    state: getOptionalText('state'),
    district: getOptionalText('district'),
    maxTotal,
    latitude,
    longitude,
    radiusKm,
    page: getPositiveInteger('page', 1, 1000000),
    limit: getPositiveInteger('limit', 20, 50),
  };
}

function getMonth(value) {
  if (typeof value !== 'string' || !/^\d{4}-(0[1-9]|1[0-2])$/.test(value)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'month must use YYYY-MM format');
  }
  const [year, month] = value.split('-').map(Number);
  const lastDay = new Date(Date.UTC(year, month, 0)).getUTCDate();
  return {
    month: value,
    periodStart: `${value}-01`,
    periodEnd: `${value}-${String(lastDay).padStart(2, '0')}`,
  };
}

function currentMalaysiaMonth() {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Kuala_Lumpur',
    year: 'numeric',
    month: '2-digit',
  }).format(new Date());
}

module.exports = {
  currentMalaysiaMonth,
  getBody,
  getBoolean,
  getBestPlacesQuery,
  getItemCode,
  getMonth,
  getName,
  getPositiveDecimal,
  getUuid,
  rejectUnknownFields,
};
