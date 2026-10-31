import MapKit
import SwiftData
import SwiftUI

/// 좌표가 있는 일정을 지도에 표시로 보여 준다. 좌표는 아직 어디서도 채우지 않아 지금은 비어 있는 게 정상이다.
struct PlacesView: View {
    @Query(sort: \Moment.start, order: .reverse) private var moments: [Moment]

    var body: some View {
        let located = moments.filter { $0.latitude != nil && $0.longitude != nil }
        Map {
            ForEach(located) { moment in
                if let latitude = moment.latitude, let longitude = moment.longitude {
                    Marker(moment.placeName ?? moment.title, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                }
            }
        }
        .overlay {
            if located.isEmpty {
                ContentUnavailableView("아직 장소가 있는 일정이 없다", systemImage: "map", description: Text("사진을 읽는 기능이 들어오면 여기에 보인다."))
                    .frame(maxWidth: 320, maxHeight: 220)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
