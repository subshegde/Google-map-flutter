import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_map/consts/consts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MyMaps extends StatefulWidget {
  const MyMaps({super.key});

  @override
  State<MyMaps> createState() => _MyMapsState();
}

class _MyMapsState extends State<MyMaps> {
  final Location _locationController = Location();

  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

  static const LatLng _pGooglePlex = LatLng(13.184570,77.479279);
  static const LatLng _pSirsi = LatLng(14.617094,74.844864);

  LatLng? _currentPosition = null;

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then((_){
      getPolylinePoints().then((coordinates){
        generatePolylineFromPoints(coordinates);
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: 
      _currentPosition == null ? const Center(child: Text('Loading...'),) :
      GoogleMap(
        onMapCreated: ((GoogleMapController controller)=> _mapController.complete(controller)),
        initialCameraPosition: CameraPosition(target: _pGooglePlex,zoom: 13),
        markers: {
          Marker(markerId: const MarkerId('_currentLocation'),
          icon: BitmapDescriptor.defaultMarker,
          position: _currentPosition!
          ),
          // Marker(markerId: MarkerId('_sourceLocation'),
          // icon: BitmapDescriptor.defaultMarker,
          // position: _pGooglePlex
          // ),
          // Marker(markerId: MarkerId('_destinationLocation'),
          // icon: BitmapDescriptor.defaultMarker,
          // position: _pSirsi
          // ),
        },
        polylines: Set<Polyline>.of(polylines.values),
        )),
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async{
    final GoogleMapController controller = await _mapController.future;
    CameraPosition newCameraPosition = CameraPosition(target: pos,zoom: 13);
    await controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));

  }

  Future<void> getLocationUpdates() async{
    bool serviceEnabled;
    PermissionStatus _permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if(serviceEnabled){
      serviceEnabled = await _locationController.requestService();
    }else{
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if(_permissionGranted == PermissionStatus.denied){
      _permissionGranted = await _locationController.requestPermission();
      if(_permissionGranted == PermissionStatus.granted){
        return;
      }
    }

    _locationController.onLocationChanged.listen((LocationData _currentLocation){
      if(_currentLocation.latitude != null && _currentLocation.longitude != null){
        setState(() {
          _currentPosition = LatLng(_currentLocation.latitude!, _currentLocation.longitude!);
          _cameraToPosition(_currentPosition!);
        });

      }
    });
  }

  Future<List<LatLng>> getPolylinePoints()async{
    List<LatLng> polyLineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(origin: PointLatLng(_pGooglePlex.latitude,_pGooglePlex.longitude), destination: PointLatLng(_pSirsi.latitude,_pSirsi.longitude), mode: TravelMode.walking),
      googleApiKey: apiKey
      );

      if(result.points.isNotEmpty){
        result.points.forEach((PointLatLng point){
          polyLineCoordinates.add(LatLng(point.latitude,point.longitude));
        });
      }else{
        print(result.errorMessage);
      }
      return polyLineCoordinates;
  }

  void generatePolylineFromPoints(List<LatLng> polyLineCoordinates)async{
    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(polylineId: id,color: Colors.black,points: polyLineCoordinates,width: 8);
    setState(() {
      polylines[id] = polyline;
    });
  }
}
