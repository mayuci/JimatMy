const express = require('express');
const {
  getPremise,
  getPremiseFilters,
  listNearbyPremises,
  listPremises,
  resolveNavigation,
  resolvePremiseLocation,
} = require('../controllers/premise_controller');

const router = express.Router();

router.get('/', listPremises);
router.get('/nearby', listNearbyPremises);
router.get('/filters', getPremiseFilters);
router.post('/:premiseCode/resolve-location', resolvePremiseLocation);
router.post('/:premiseCode/resolve-navigation', resolveNavigation);
router.get('/:premiseCode', getPremise);

module.exports = router;
