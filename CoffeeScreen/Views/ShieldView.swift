import SwiftUI

/// 화면을 가리는 Shield 뷰
struct ShieldView: View {
    @ObservedObject var viewModel: ShieldViewModel

    var body: some View {
        ZStack {
            // 검은 배경
            Color.black
                .ignoresSafeArea()

            // 잠금 해제 UI
            UnlockView(viewModel: viewModel)
        }
    }
}

#Preview {
    ShieldView(viewModel: ShieldViewModel())
}
