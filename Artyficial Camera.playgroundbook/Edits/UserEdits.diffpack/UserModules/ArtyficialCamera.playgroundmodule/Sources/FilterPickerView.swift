//
//  FilterPickerView.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 15/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import SwiftUI
import CoreImage
import CoreML

struct FilterPickerView: View {
    @Binding var withImage: Bool
    @State var filterPickerDelegate: FilterPickerDelegate?
    @State var filters: [Filter]
    
    var body: some View {
        VStack {
            FilterPicker(
                withImage: $withImage,
                filterData: filters.map({ $0.pickerItemData}),
                delegate: filterPickerDelegate,
                tileSize: 100,
                tileSpacing: 20)
            Circle()
                .fill(Color.gray)
                .frame(width: 10, height: 10, alignment: .center)
                .padding(5)
        }
        
    }
}

#if DEBUG
struct FilterPickerView_Preview: PreviewProvider {
    @State static var withImage = true
    @State static var filterPickerDelegate: FilterPickerDelegate? = nil
    @State static var filters = Filter.allCases
    @State static var selectedFilter = Filter.none
    
    static var previews: some View {
        FilterPickerView(
            withImage: $withImage,
            filterPickerDelegate: filterPickerDelegate,
            filters: filters
        )
            .frame(height: 300, alignment: .center)
    }
}
#endif
