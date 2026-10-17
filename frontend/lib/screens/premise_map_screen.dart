import 'package:flutter/material.dart';

import '../models/premise.dart';
import '../services/location_service.dart';
import '../widgets/premise_map_widget.dart';

class PremiseMapScreen extends StatelessWidget {
  const PremiseMapScreen({
    required this.premises,
    this.selectedPremise,
    this.userLocation,
    super.key,
  });
  final List<Premise> premises;
  final Premise? selectedPremise;
  final UserLocation? userLocation;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(selectedPremise?.premiseName ?? 'Nearby stores map'),
    ),
    body: PremiseMapWidget(
      premises: premises,
      selectedPremise: selectedPremise,
      userLocation: userLocation,
    ),
  );
}
