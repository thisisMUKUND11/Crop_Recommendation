class SustainabilityService {
  // Mock data for sustainability index
  final Map<String, Map<String, dynamic>> _sustainabilityData = {
    'Wheat': {
      'water_requirement': 'Low', // Low, Medium, High
      'soil_health_impact': 'Good', // Poor, Average, Good
    },
    'Rice': {
      'water_requirement': 'High',
      'soil_health_impact': 'Average',
    },
    'Mustard': {
      'water_requirement': 'Low',
      'soil_health_impact': 'Good',
    },
    'Cotton': {
      'water_requirement': 'High',
      'soil_health_impact': 'Average',
    },
    'Sugarcane': {
      'water_requirement': 'High',
      'soil_health_impact': 'Poor',
    },
    'Jowar': {
      'water_requirement': 'Low',
      'soil_health_impact': 'Good',
    },
    'Bajra': {
      'water_requirement': 'Low',
      'soil_health_impact': 'Good',
    },
    'Ragi': {
      'water_requirement': 'Low',
      'soil_health_impact': 'Good',
    },
    'Groundnut': {
      'water_requirement': 'Medium',
      'soil_health_impact': 'Good',
    },
    'Soybean': {
      'water_requirement': 'Medium',
      'soil_health_impact': 'Good',
    },
    'Tea': {
      'water_requirement': 'High',
      'soil_health_impact': 'Poor',
    },
    'Jute': {
      'water_requirement': 'High',
      'soil_health_impact': 'Average',
    },
    'Potato': {
      'water_requirement': 'Medium',
      'soil_health_impact': 'Average',
    },
    'Peas': {
      'water_requirement': 'Low',
      'soil_health_impact': 'Good',
    },
    'Barley': {
      'water_requirement': 'Low',
      'soil_health_impact': 'Good',
    },
    'Coconut': {
      'water_requirement': 'Medium',
      'soil_health_impact': 'Average',
    },
    'Maize': {
      'water_requirement': 'Medium',
      'soil_health_impact': 'Average',
    },
    'Pulses': {
      'water_requirement': 'Low',
      'soil_health_impact': 'Good',
    },
  };

  Future<Map<String, dynamic>> getSustainabilityIndex(String crop) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate async operation
    return _sustainabilityData[crop] ??
        {
          'water_requirement': 'Unknown',
          'soil_health_impact': 'Unknown',
        };
  }
}
