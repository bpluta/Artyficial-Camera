//
//  FilterPickerItemView.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 17/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import SwiftUI

struct FilterPickerItemView: View {
    @Binding var withImage: Bool
    @State var data: FilterPickerItem
    
    var body: some View {
        VStack {
            Text(data.name)
                .foregroundColor(.white)
                .font(.callout)
                .fontWeight(.regular)
            if withImage {
                image
                    .cornerRadius(10)
                    .frame(width: 100, height: 100, alignment: .center)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.gray), lineWidth: 5))
            }
        }
    }
    
    var image: some View {
        if let image = UIImage(named: data.imageName ?? "") {
            return AnyView(Image(uiImage: image).resizable().scaledToFit())
        } else {
            return AnyView(Rectangle())
        }
    }
}

