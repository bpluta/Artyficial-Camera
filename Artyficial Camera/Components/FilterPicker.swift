//
//  FilterPicker.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 17/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import SwiftUI

protocol FilterPickerDelegate {
    func selectFilter(filter: FilterPickerItem)
}

struct FilterPicker: View {
    @Binding var withImage: Bool
    @State var horizionalOffset: CGFloat = 0
    @State var count: CGFloat = 0
    
    @State private var currentWidth: CGFloat = 0
    @State private var newWidth: CGFloat = 0
    
    @State var filterData: [FilterPickerItem]
    
    var delegate: FilterPickerDelegate? = nil
    
    let tileSize: CGFloat
    let tileSpacing: CGFloat
    
    private var initialPosition: CGFloat {
        ((CGFloat(filterData.count) - 1) / 2) * (tileSize + tileSpacing)
    }
    
    var body: some View {
        HStack(spacing: tileSpacing) {
            ForEach(filterData, id: \.type) { filter in
                FilterPickerItemView(withImage: self.$withImage, data: filter)
                    .offset(x: self.currentWidth)
                    .highPriorityGesture(DragGesture()
                    .onChanged { value in
                        self.currentWidth = value.translation.width + self.newWidth
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            let currentPosition = value.translation.width + self.newWidth
                            let index = self.getClosestIndex(to: currentPosition)
                            let newPosition = self.getStaticPosition(index: index)
                            self.currentWidth = newPosition
                            self.newWidth = newPosition
                            self.updateCurrentIndex(index: index)
                        }
                    }
                )
                .frame(width: self.tileSize)
            }
        }
        .onAppear {
            self.currentWidth = self.initialPosition
        }
    }
    
    private func updateCurrentIndex(position: CGFloat) {
        let index = self.getClosestIndex(to: position)
        updateCurrentIndex(index: index)
    }
    
    private func updateCurrentIndex(index: Int) {
        delegate?.selectFilter(filter: filterData[index])
    }
    
    private func getStaticPosition(index: Int) -> CGFloat {
        initialPosition - CGFloat(index) * (tileSize + tileSpacing)
    }
    
    private func getClosestIndex(to position: CGFloat) -> Int {
        let size = tileSize + tileSpacing
        let offset = Int(((initialPosition - position) / size).rounded())
        guard offset > 0 else { return 0 }
        guard offset < filterData.count else { return filterData.count - 1 }
        return offset
    }
}
