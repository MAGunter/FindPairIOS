// MARK: - FindPairApp.swift
import SwiftUI

@main
struct FindPairApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
    }
}

// MARK: - MainMenuView.swift
struct MainMenuView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Find Pair")
                    .font(.largeTitle).bold()
                Text("Choose board size")
                    .foregroundStyle(.secondary)
                NavigationLink("2 × 2", destination: GameView(size: .twoByTwo))
                    .buttonStyle(.borderedProminent)
                NavigationLink("4 × 4", destination: GameView(size: .fourByFour))
                    .buttonStyle(.bordered)
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Game Types & Model
enum BoardSize: Int {
    case twoByTwo = 4
    case fourByFour = 16

    var columns: [GridItem] {
        switch self {
        case .twoByTwo: return Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        case .fourByFour: return Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
        }
    }
}

struct Card: Identifiable, Hashable {
    let id: UUID = UUID()
    let emoji: String
    var isRevealed: Bool = false
    var isMatched: Bool = false
}

// MARK: - GameState (ViewModel)
@Observable class GameState {
    @Published private(set) var cards: [Card] = []
    @Published var hasWon: Bool = false

    // indices of currently face-up but not matched cards (at most 2)
    private var selection: [Int] = []

    private let allEmojis = [
        "🐶","🐱","🐭","🦊","🐻","🐼","🐨","🐯",
        "🐷","🐸","🐵","🐔","🐧","🐦","🦄","🐙",
        "🍎","🍊","🍋","🍉","🍇","🍓","🍒","🥝",
        "⚽️","🏀","🏈","⚾️","🎾","🏐","🎱","🏓"
    ]

    func start(size: BoardSize) {
        hasWon = false
        selection.removeAll()

        // Choose pairs
        let pairCount = size.rawValue / 2
        var pool = allEmojis.shuffled()
        let chosen = Array(pool.prefix(pairCount))
        var deck = (chosen + chosen).shuffled().map { Card(emoji: $0) }
        self.cards = deck
    }

    func tap(at index: Int) {
        guard cards.indices.contains(index), !cards[index].isRevealed, !cards[index].isMatched else { return }

        // If two are shown and not matched yet, hide them when third is tapped
        if selection.count == 2 {
            if cards[selection[0]].emoji != cards[selection[1]].emoji {
                for i in selection { cards[i].isRevealed = false }
            }
            selection.removeAll()
        }

        // Reveal current tap
        cards[index].isRevealed = true
        selection.append(index)

        // Check match when 2 selected
        if selection.count == 2 {
            let i = selection[0], j = selection[1]
            if cards[i].emoji == cards[j].emoji {
                cards[i].isMatched = true
                cards[j].isMatched = true
                selection.removeAll()
                checkWin()
            }
        }
    }

    func restart(size: BoardSize) { start(size: size) }

    private func checkWin() {
        hasWon = cards.allSatisfy { $0.isMatched }
    }
}

// MARK: - GameView.swift
struct GameView: View {
    let size: BoardSize
    @State private var state = GameState()

    var body: some View {
        VStack(spacing: 16) {
            if state.hasWon {
                Text("Победа!")
                    .font(.title).bold()
                    .foregroundStyle(.green)
            } else {
                Text("Find all pairs")
                    .font(.title3).foregroundStyle(.secondary)
            }

            LazyVGrid(columns: size.columns, spacing: 12) {
                ForEach(state.cards.indices, id: \.self) { i in
                    CardButton(card: state.cards[i]) {
                        state.tap(at: i)
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding(.horizontal)

            Button("Restart") { state.restart(size: size) }
                .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle(size == .twoByTwo ? "2×2" : "4×4")
        .onAppear { state.start(size: size) }
    }
}

// MARK: - CardButton.swift
struct CardButton: View {
    let card: Card
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(card.isRevealed || card.isMatched ? Color(.systemGray6) : Color(.systemGray4))
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.gray.opacity(0.4))
                Text(card.isRevealed || card.isMatched ? card.emoji : "")
                    .font(.system(size: 42))
                    .minimumScaleFactor(0.5)
            }
        }
        .disabled(card.isMatched)
        .accessibilityLabel(card.isMatched ? "matched" : "card")
    }
}
