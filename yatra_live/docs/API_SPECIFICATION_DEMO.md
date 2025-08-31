# YatraLive Demo API Specification

## Overview
This document describes the demo API endpoints available in YatraLive for the Smart India Hackathon 2025 presentation. All endpoints are simulated and work without external dependencies.

## Base Configuration
- **Mode**: Demo/Simulation
- **Authentication**: Not required (demo mode)
- **Response Format**: JSON
- **Update Frequency**: 3 seconds (real-time data)

## API Endpoints

### 1. Bus Operations

#### Get Bus Details
```dart
Future<ApiResponse<Map<String, dynamic>>> getBusDetails(String busId)
```
**Description**: Get detailed information about a specific bus

**Response Example**:
```json
{
  "data": {
    "id": "bus_1",
    "busNumber": "DL01-1234",
    "status": "active",
    "currentLocation": {
      "latitude": 28.6139,
      "longitude": 77.2090
    },
    "speed": 25.5,
    "passengerCount": 32,
    "maxCapacity": 50,
    "driverInfo": {
      "name": "Driver 42",
      "rating": 4.2,
      "experience": "5 years"
    }
  },
  "message": "Success",
  "statusCode": 200
}
```

#### Get Nearby Buses
```dart
Future<ApiResponse<List<Map<String, dynamic>>>> getNearbyBuses({
  required double latitude,
  required double longitude,
  double radiusKm = 5.0,
})
```
**Description**: Find buses within a specified radius

**Response**: List of buses sorted by distance

### 2. Route Operations

#### Get Route Details
```dart
Future<ApiResponse<Map<String, dynamic>>> getRouteDetails(String routeId)
```
**Description**: Get comprehensive route information

**Response Includes**:
- Route name and distance
- Active buses on route
- Fare information (adult/child/student)
- Schedule details
- Popularity metrics

#### Search Routes
```dart
Future<ApiResponse<List<Map<String, dynamic>>>> searchRoutes(String query)
```
**Description**: Search routes by name or location

**Response**: Filtered list of matching routes

### 3. Real-time Operations

#### Calculate ETA
```dart
Future<ApiResponse<Map<String, dynamic>>> calculateETA({
  required String busId,
  required String stopId,
})
```
**Description**: Calculate estimated time of arrival

**Response Example**:
```json
{
  "data": {
    "busId": "bus_1",
    "stopId": "stop_2",
    "estimatedTime": 12,
    "distance": 3.5,
    "trafficCondition": "moderate",
    "confidence": 85.2,
    "lastUpdated": "2025-01-30T10:30:00Z"
  }
}
```

#### Batch Get Bus Locations
```dart
Future<ApiResponse<List<Map<String, dynamic>>>> batchGetBusLocations(
  List<String> busIds,
)
```
**Description**: Get locations for multiple buses in one request

### 4. Feedback Operations

#### Submit Feedback
```dart
Future<ApiResponse<Map<String, dynamic>>> submitFeedback({
  required String type,
  required Map<String, dynamic> data,
})
```
**Description**: Submit passenger feedback

**Feedback Types**:
- `delay`: Report bus delays
- `crowding`: Report crowding levels
- `service`: General service feedback
- `driver`: Driver-specific feedback

### 5. Analytics

#### Get Route Analytics
```dart
Future<ApiResponse<Map<String, dynamic>>> getRouteAnalytics(String routeId)
```
**Description**: Get analytical data for a route

**Response Includes**:
- Daily ridership statistics
- Average delay metrics
- Peak hour information
- Satisfaction scores
- Crowding patterns

### 6. System Operations

#### Health Check
```dart
Future<ApiResponse<Map<String, dynamic>>> healthCheck()
```
**Description**: Check system health status

**Response Example**:
```json
{
  "data": {
    "status": "healthy",
    "version": "1.0.0",
    "services": {
      "database": "connected",
      "notifications": "active",
      "location": "tracking",
      "analytics": "running"
    },
    "timestamp": "2025-01-30T10:30:00Z"
  }
}
```

## Response Format

### Success Response
```dart
class ApiResponse<T> {
  final T? data;           // Response data
  final String message;    // Success/error message
  final int statusCode;    // HTTP status code
  final DateTime timestamp; // Response timestamp
  final bool isError;      // Error flag
}
```

### Error Codes
- `200`: Success
- `400`: Bad Request
- `404`: Not Found
- `500`: Internal Server Error (simulated)

## Demo Features

### Simulated Behaviors
1. **Network Delay**: 200-500ms random delay
2. **Data Variation**: Random variations in passenger count, speed, etc.
3. **Auto-updates**: Data changes every 3 seconds
4. **Error Simulation**: Occasional error responses for testing

### Demo Limitations
- All data is generated in-memory
- No persistence between app restarts
- Limited to predefined routes and buses
- Notifications are simulated, not push

## Usage Example

```dart
// Initialize demo services
await DemoInitializer.initialize();

// Get API service instance
final apiService = ApiServiceDemo();

// Make API call
final response = await apiService.getBusDetails('bus_1');

if (response.isSuccess) {
  print('Bus Number: ${response.data!['busNumber']}');
  print('Status: ${response.data!['status']}');
} else {
  print('Error: ${response.message}');
}
```

## Testing the API

### Quick Test Script
```dart
// Test all major endpoints
void testDemoAPI() async {
  final api = ApiServiceDemo();
  
  // 1. Health check
  final health = await api.healthCheck();
  print('System Status: ${health.data!['status']}');
  
  // 2. Get bus details
  final bus = await api.getBusDetails('bus_1');
  print('Bus Location: ${bus.data!['currentLocation']}');
  
  // 3. Search routes
  final routes = await api.searchRoutes('Connaught');
  print('Found ${routes.data!.length} routes');
  
  // 4. Calculate ETA
  final eta = await api.calculateETA(
    busId: 'bus_1',
    stopId: 'stop_2',
  );
  print('ETA: ${eta.data!['estimatedTime']} minutes');
}
```

## Notes for Hackathon Demo

1. **No Setup Required**: All endpoints work immediately
2. **Realistic Data**: Simulated data follows real-world patterns
3. **Error Handling**: Gracefully handles all error scenarios
4. **Performance**: Optimized for smooth demo experience
5. **Scalability**: Architecture supports easy migration to real APIs

---

**Created for Smart India Hackathon 2025**
*YatraLive - Transforming Indian Public Transportation*
