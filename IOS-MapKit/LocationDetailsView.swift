//
//  LocationDetailView.swift
//  IOS-MapKit
//
//  Created by Đoàn Văn Khoan on 29/02/2024.
//

import SwiftUI
import MapKit

struct LocationDetailsView: View {
    @Binding var mapSelection : MKMapItem?
    @Binding var showDetails : Bool
    @State var lookAroundScence : MKLookAroundScene?
    @Binding var getDirections : Bool
    
    var body: some View {
        VStack{
            HStack{
                VStack{
                    Text(mapSelection?.placemark.name ?? "")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(mapSelection?.placemark.title ?? "")
                        .font(.footnote)
                        .foregroundStyle(Color(.systemGray2))
                        .lineLimit(2)
                        .padding(.trailing)
                }
                
                Spacer()
                
                Button{
                    showDetails.toggle()
                    mapSelection = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color(.systemGray6))
                }
            }
            
            Spacer()
            
            if let scence = lookAroundScence {
                LookAroundPreview(initialScene : scence) // set image of location if avaiable
                    .frame(height: 200)
                    .cornerRadius(22)
                    .padding()
            } else {
                ContentUnavailableView("No Preview Avaiable", systemImage: "eye.slash")
            }
            
            HStack{
                Button{
                    if let mapSelection {
                        mapSelection.openInMaps() // open actually app in phone
                    }
                } label: {
                    Text("Open in Map")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 170, height: 48)
                        .background(.green)
                        .cornerRadius(22)
                }
                
                Button{
                    getDirections = true
                    showDetails = false
                } label: {
                    Text("Get Directions")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 170, height: 48)
                        .background(.blue)
                        .cornerRadius(22)
                }
            }
        }
        .onAppear{
            fetchLookAroundScence()
        }
        .onChange(of: mapSelection){ oldValue, newValue in
            fetchLookAroundScence()
        }
        .padding()
    }
}

extension LocationDetailsView{
    func fetchLookAroundScence(){
        if let mapSelection{
            lookAroundScence = nil
            Task{
                let request = MKLookAroundSceneRequest(mapItem: mapSelection)
                lookAroundScence = try? await request.scene
            }
        }
    }
}


#Preview {
    LocationDetailsView(mapSelection: .constant(nil), showDetails: .constant(false), getDirections: .constant(false))
}
