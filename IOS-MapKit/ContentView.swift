//
//  ContentView.swift
//  IOS-MapKit
//
//  Created by Đoàn Văn Khoan on 29/02/2024.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var cameraPosition : MapCameraPosition = .region(.userRegion)
    @State private var searchText = ""
    @State private var results = [MKMapItem]()
    @State private var mapSelection : MKMapItem? // can interact any position after search
    @State private var showDetails = false
    @State private var getDirections = false
    @State private var routeDisplaying = false
    @State private var route : MKRoute?
    @State private var routeDestination : MKMapItem?
    
    
    var body: some View {
        Map(position: $cameraPosition, selection: $mapSelection){
            //            Marker("My location", systemImage: "paperplane" , coordinate: .userLocation)
            //        }
            
            Annotation("My Location", coordinate: .userLocation){
                ZStack{
                    Circle()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.blue.opacity(0.25))
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                    Circle()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.blue)
                }
            }
            
            
            ForEach(results, id : \.self){ item in
                if routeDisplaying{
                    if item == routeDestination { // only see 1 place if routeDestination don't nil, another will invisible
                        let placemark = item.placemark
                        Marker(placemark.name ?? "", coordinate: placemark.coordinate)// display name and coordinate()
                    }
                } else {
                    let placemark = item.placemark
                    Marker(placemark.name ?? "", coordinate: placemark.coordinate) // display name and coordinate()
                }
            }
            
            if let route {
                MapPolyline(route.polyline) // display pipeline way
                    .stroke(.blue, lineWidth: 6)
            }
        }
        .overlay(alignment : .top){
            TextField("Search for a location...", text: $searchText)
                .font(.subheadline)
                .padding(22)
                .background(.white)
                .padding()
                .shadow(radius: 10)
        }
        .onSubmit(of: .text) { // whenever user click enter return text or textfield
            Task{
                await searchPlaces()
            }
        }
        .onChange(of: getDirections) { oldValue, newValue in
            if newValue {
                fetchRoute()
            }
        }
        .onChange(of: mapSelection, { oldValue, newValue in
            showDetails = newValue != nil // if newValue not nil will show Detail
        })
        .sheet(isPresented: $showDetails, content: {
            LocationDetailsView(mapSelection: $mapSelection, showDetails: $showDetails, getDirections : $getDirections)
                .presentationDetents([.height(340)]) // set height for sheet
                .presentationBackgroundInteraction(.enabled(upThrough: .height(340))) // enable interact outside the sheet, i mean our can scroll or scale it
                .presentationCornerRadius(12)
        })
        .mapControls{
            MapCompass() //can zoom by 2 fingers
            MapPitchToggle() // when i zoom adequate small then i will see the button 3D map
            MapUserLocationButton() // appear icon turn back user location
        }
    }
}

#Preview {
    ContentView()
}


extension CLLocationCoordinate2D{ // the main position with latitude and longtitude
    static var userLocation : CLLocationCoordinate2D {
        return .init(latitude: 10.742610, longitude: 106.685750)
    }
}

extension MKCoordinateRegion{ // the meters scale in screen
    static var userRegion : MKCoordinateRegion{
        return .init(center: .userLocation, latitudinalMeters: 100, longitudinalMeters: 100)
    }
}

extension ContentView{
    func searchPlaces() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText // convert text string to natural language
        request.region = .userRegion
        let results = try? await MKLocalSearch(request: request).start()
        self.results = results?.mapItems ?? []
    }
    
    func fetchRoute(){
        if let mapSelection {
            let request = MKDirections.Request() // require MKDirections for manage direction start and finish
            request.source = MKMapItem(placemark: .init(coordinate: .userLocation)) // set location department
            request.destination = mapSelection // set location destination
            
            Task{
                let result = try? await MKDirections(request: request).calculate()
                route = result?.routes.first // return the first route it found
                routeDestination = mapSelection
                
                withAnimation(.snappy){
                    routeDisplaying = true
                    showDetails = false
                    
                    if let rect = route?.polyline.boundingMapRect, routeDisplaying { // find the best screen for see polyline
                        cameraPosition = .rect(rect)
                    }
                }
            }
        }
    }
}
