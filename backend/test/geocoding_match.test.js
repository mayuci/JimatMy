const test = require('node:test');
const assert = require('node:assert/strict');
const {
  buildGeocodingAddress,
  normalizeOfficialText,
  scoreGeocodingMatch,
} = require('../src/controllers/premise_controller');

const premise = {
  premise: 'PASAR MINI TEST (PJ)',
  address: 'NO 2,JLN PJU 1A/41B,ARA JAYA,47301 PETALING JAYA',
  district: 'PETALING',
  state: 'SELANGOR',
};

test('normalizes malformed spacing and JLN without changing the source object', () => {
  const original = { ...premise };
  assert.equal(
    normalizeOfficialText(' NO 2,JLN  PJU 1A/41B '),
    'NO 2, JALAN PJU 1A/41B',
  );
  assert.match(buildGeocodingAddress(premise), /NO 2, JALAN PJU 1A\/41B/);
  assert.deepEqual(premise, original);
});

test('scores a matching branch address as high confidence', () => {
  assert.equal(
    scoreGeocodingMatch(premise, '2, Jalan PJU 1A/41B, Ara Jaya, 47301 Petaling Jaya, Selangor, Malaysia'),
    'high',
  );
});

test('scores partial local evidence as possible', () => {
  assert.equal(
    scoreGeocodingMatch(premise, 'Ara Jaya, Petaling Jaya, Selangor, Malaysia'),
    'possible',
  );
});

test('rejects mismatched postcode and state as low or ambiguous', () => {
  assert.equal(
    scoreGeocodingMatch(premise, 'Jalan Store, 80000 Johor Bahru, Johor, Malaysia'),
    'low_ambiguous',
  );
});
