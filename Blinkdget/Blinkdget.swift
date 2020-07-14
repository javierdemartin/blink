//////////////////////////////////////////////////////////////////////////////////
//
// B L I N K
//
// Copyright (C) 2016-2019 Blink Mobile Shell Project
//
// This file is part of Blink.
//
// Blink is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Blink is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Blink. If not, see <http://www.gnu.org/licenses/>.
//
// In addition, Blink is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Blink Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
//
////////////////////////////////////////////////////////////////////////////////


import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
  
  @AppStorage("history", store: UserDefaults(suiteName: BlinkdgetDefaults.groupUserDefaults))
  var commandData: Data = Data()
  
  public typealias Entry = CommandEntryShown
  
  // Sample data
  public func snapshot(with context: Context, completion: @escaping (CommandEntryShown) -> ()) {
    
    guard let commands = try? JSONDecoder().decode([LastCommandEntry].self, from: commandData) else {
      return
    }
    
    let toShow = CommandEntryShown(date: Date(), numberOfActiveSessions: 0, commands: commands.reversed())
    
    completion(toShow)
  }
  
  public func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    
    guard let commands = try? JSONDecoder().decode([LastCommandEntry].self, from: commandData) else {
      return
    }
    
    dump(commands)
    
    let timeline = Timeline(entries: [CommandEntryShown(date: Date(), numberOfActiveSessions: 0, commands: commands.reversed())], policy: .atEnd)
    
    completion(timeline)
  }
}

struct PlaceholderView : View {
  
  var body: some View {
    VStack(alignment: .leading) {
      BlinkdgetItem(commandHistory: CommandHistory(command: "hola", commandUrl: nil))
        .padding(7)
        .overlay(
          RoundedRectangle(cornerRadius: 9)
            .stroke(Color("BlinkTint"), lineWidth: 4)
        )
    }
    
    // TODO: add .isPlaceholder(true). Not yet available in beta 2 (neither beta 1)
    // Source: https://developer.apple.com/forums/thread/650564
  }
}

struct BlinkdgetItem: View {
  
  @Environment(\.widgetFamily) var family
  let commandHistory: CommandHistory
  
  var body: some View {
    
    if let commandUrl = commandHistory.commandUrl {
      HStack {
        switch family {
        case .systemMedium, .systemLarge:
          Image(systemName: "chevron.right")
            .foregroundColor(Color("BlinkTint"))
            .padding(.leading, 5)
        default:
          Image(systemName: "chevron.right")
            .foregroundColor(Color("BlinkTint"))
        }
        
        Link(commandHistory.command, destination: commandUrl)
          .font(.system(.body, design: .monospaced))
      }
      
    } else {
      HStack {
        Image(systemName: "chevron.right")
        Text(commandHistory.command)
          .font(.system(.body, design: .monospaced))
      }
    }
  }
}

struct BlinkdgetHeaderView: View {
    
    @State var numberOfActiveSessions: Int
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        HStack(spacing: -5) {
          Image(systemName: "\(numberOfActiveSessions).circle.fill")
            .foregroundColor(Color("BlinkTint"))
            .font(.system(size: 30, weight: .regular))
            .padding()
          VStack(alignment: .leading) {
            switch family {
            case .systemSmall:
                Text("Sessions")
                  .font(.system(.body, design: .rounded))
                  .bold()
                  .lineLimit(1)
            default:
                Text("Active Sessions")
                  .font(.system(.body, design: .rounded))
                  .bold()
                  .lineLimit(1)
            }
            
            (Text(Date(),style: .time))
              .font(.system(.caption, design: .rounded))
          }
            
          Spacer()
          
        }
    }
}

struct BlinkdgetCommandHistoryView: View {
    
//    @Environment(\.widgetFamily) var family
    @State var commands: [LastCommandEntry]
    
    var body: some View {
        ForEach((0...1), id: \.self) { i in
            BlinkdgetItem(commandHistory: commands[i].command)
          
          if i != 1 {
            Divider()
                .frame(height: 1)
                .background(Color("BlinkTint"))
          }
        }
    }
}

struct BlinkdgetEntryView : View {
    var entry: CommandEntryShown
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        
        
        switch family {
        case .systemSmall:
          VStack(alignment: .leading) {
            
            BlinkdgetHeaderView(numberOfActiveSessions: entry.numberOfActiveSessions)
            
            BlinkdgetCommandHistoryView(commands: entry.commands)
            Spacer()
              
              
          }
          .padding([.leading, .trailing], 5)

        case .systemMedium:
          VStack(alignment: .leading) {
            
            BlinkdgetHeaderView(numberOfActiveSessions: entry.numberOfActiveSessions)
              
            BlinkdgetCommandHistoryView(commands: entry.commands)
            Spacer()

          }
          .padding(7)


        default:
          VStack(alignment: .leading) {
            
            BlinkdgetHeaderView(numberOfActiveSessions: entry.numberOfActiveSessions)
              
            BlinkdgetCommandHistoryView(commands: entry.commands)
            
              Spacer()
          }
          .padding(7)

        }
        
    }
}


// This defines a Widget, structs that inherits from widget and configures its capabilities
@main
struct Blinkdget: Widget {
  // Has to be the exact same name as the struct
  private let kind: String = "Blinkdget"
  
  let displayName: LocalizedStringKey = "WIDGET_NAME"
  let displayDescription: LocalizedStringKey = "WIDGET_DESCRIPTION"
  
  public var body: some WidgetConfiguration {
    
    StaticConfiguration(
      kind: kind,
      provider: Provider(),
      placeholder: PlaceholderView()
    ) { entry in
      BlinkdgetEntryView(entry: entry)
    }
    .configurationDisplayName("Blink Shell")
    .description("Latest run commands")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

