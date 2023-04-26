//
//  ActivityWidget.swift
//  ActivityWidget
//
//  Created by Inumaki on 26.04.23.
//

import WidgetKit
import SwiftUI
import Intents

struct AnilistResponse: Codable {
    var data: AnilistData
}

struct AnilistData: Codable {
    var User: UserData
}

struct UserData: Codable {
    let id: Int
    let name: String
    var stats: UserStats
}

struct UserStats: Codable {
    var activityHistory: [ActivityHistory]
}

struct ActivityHistory: Codable {
    let date: Int
    let amount: Int
    let level: Int
}

struct ExampleTimelineProvider: TimelineProvider {
    typealias Entry = ExampleTimelineEntry
    
    // Provides a timeline entry representing a placeholder version of the widget.
    func placeholder(in context: Context) -> ExampleTimelineEntry {
        return ExampleTimelineEntry(date: .now, history: [])
    }
    
    // Provides a timeline entry that represents the current time and state of a widget.
    func getSnapshot(in context: Context, completion: @escaping (ExampleTimelineEntry) -> Void) {
        
    }
    
    // Provides an array of timeline entries for the current time and, optionally, any future times to update a widget.
    func getTimeline(in context: Context, completion: @escaping (Timeline<ExampleTimelineEntry>) -> Void) {
        Task {
            let query = """
                        {
                          User(name: "huntg") {
                            id
                            name
                            options {
                              profileColor
                            }
                            stats {
                              activityHistory {
                                date
                                amount
                                level
                              }
                            }
                          }
                        }
                    
                    """
            let jsonData = try? JSONSerialization.data(withJSONObject: ["query": query])
            
            let url = URL(string: "https://graphql.anilist.co")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = jsonData
            
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                do {
                    var data = try JSONDecoder().decode(AnilistResponse.self, from: data)
                    print(data)
                    data.data.User.stats.activityHistory.reverse()
                    let entry = ExampleTimelineEntry(date: Date(), history: data.data.User.stats.activityHistory)
                            let timeline = Timeline(entries: [entry],
                                                    policy: .after(Date.now + (24 * 60 * 60)) )
                            completion(timeline)
                } catch let error {
                    print(error.localizedDescription)
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
}

struct ExampleTimelineEntry: TimelineEntry {
    var date: Date
    let history: [ActivityHistory]
}

struct ActivityWidgetEntryView : View {
    var entry: ExampleTimelineProvider.Entry
    
    let sizing: Double = 16
    
    var body: some View {
        GeometryReader { proxy in
            if entry.history.count > 0 {
                
                LazyHGrid(
                    rows: [
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                    ],
                    spacing: 2
                ) {
                    ForEach(0..<min(49, entry.history.count)) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.black)
                                .frame(width: proxy.size.width / 7 - (2), height: proxy.size.width / 7 - (2))
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color("AccentColor"))
                                .frame(width: proxy.size.width / 7 - (2), height: proxy.size.width / 7 - (2))
                                .opacity(0.1 * Double(entry.history[index].level))
                        }
                    }
                }
            }
        }
        .cornerRadius(8)
        .padding(16)
        .foregroundColor(Color("TextColor"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}

@main
struct ActivityWidget: Widget {
    let kind: String = "ActivityWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.inumaki.AnilistWidget",
            provider: ExampleTimelineProvider()
        ) { entry in
            ActivityWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Anilist Activity")
        .description("A Widget to display your anilist activity")
        .supportedFamilies([.systemSmall])
    }
}

struct ActivityWidget_Previews: PreviewProvider {
    static var previews: some View {
        ActivityWidgetEntryView(entry: ExampleTimelineEntry(date: .now, history: []))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
