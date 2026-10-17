const DAY_MS = 24 * 60 * 60 * 1000;

function normalizeRecordDate(recordDate) {
  if (!recordDate) return null;
  if (recordDate instanceof Date && !Number.isNaN(recordDate.valueOf())) {
    return recordDate.toISOString().slice(0, 10);
  }
  const text = String(recordDate).slice(0, 10);
  return /^\d{4}-\d{2}-\d{2}$/.test(text) ? text : null;
}

function daysSince(recordDate, now = new Date()) {
  const normalized = normalizeRecordDate(recordDate);
  if (!normalized) return null;
  const parsed = new Date(`${normalized}T00:00:00Z`);
  if (Number.isNaN(parsed.valueOf())) return null;
  const today = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  return Math.max(0, Math.floor((today - parsed.valueOf()) / DAY_MS));
}

function freshnessStatus(ageDays) {
  if (ageDays === null) return 'unavailable';
  if (ageDays <= 7) return 'fresh';
  if (ageDays <= 30) return 'recent';
  return 'old';
}

function coverageStatus(premiseCount) {
  const count = Number(premiseCount || 0);
  if (count === 0) return 'unavailable';
  if (count <= 4) return 'limited';
  if (count <= 19) return 'moderate';
  return 'wide';
}

function priceReliability(recordDate, premiseCount, now = new Date()) {
  const normalized = normalizeRecordDate(recordDate);
  const ageDays = daysSince(recordDate, now);
  return {
    latestRecordDate: normalized,
    ageDays,
    premiseCount: Number(premiseCount || 0),
    freshnessStatus: freshnessStatus(ageDays),
    coverageStatus: coverageStatus(premiseCount),
  };
}

module.exports = {
  coverageStatus, daysSince, freshnessStatus, normalizeRecordDate, priceReliability,
};
