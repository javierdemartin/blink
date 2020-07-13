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
  
  @AppStorage("history", store: UserDefaults(suiteName: "group.com.carloscabanero"))
  var commandData: Data = Data()
  
  public typealias Entry = CommandEntryShown
  
  // Sample data
  public func snapshot(with context: Context, completion: @escaping (CommandEntryShown) -> ()) {
    
    guard let commands = try? JSONDecoder().decode([LastCommandEntry].self, from: commandData) else {
      return
    }
    
    let toShow = CommandEntryShown(date: Date(), commands: commands.reversed())
    
    completion(toShow)
  }
  
  public func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    
    guard let commands = try? JSONDecoder().decode([LastCommandEntry].self, from: commandData) else {
      return
    }
    
    dump(commands)
    
    let timeline = Timeline(entries: [CommandEntryShown(date: Date(), commands: commands.reversed())], policy: .atEnd)
    
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
            .stroke(Color(UIColor(red: 7/255, green: 191/255, blue: 204/255, alpha: 1.0)), lineWidth: 4)
        )
    }
  }
}

struct BlinkdgetItem: View {
  
  let commandHistory: CommandHistory
  
  var body: some View {
    
    if let commandUrl = commandHistory.commandUrl {
      HStack {
        Image(systemName: "chevron.right")
          .foregroundColor(Color(UIColor(red: 7/255, green: 191/255, blue: 204/255, alpha: 1.0)))
        //          Button(action: {
        //              // your action here
        //            UIApplication.shared.open(commandUrl)
        //          }) {
        //            Text(commandHistory.command)
        //              .font(.system(.body, design: .monospaced))
        //          }
        
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

struct BlinkdgetEntryView : View {
  var entry: Provider.Entry
  
  @Environment(\.widgetFamily) var family
  
  @ViewBuilder
  var body: some View {
    
    if entry.commands.count == 0 {
      
      PlaceholderView()
      Text("Enable x-callback-url to enable interactiveness")
      
    } else {
      
      switch family {
      case .systemSmall:
        VStack(alignment: .leading) {
          ForEach((0...2), id: \.self) { i in
            BlinkdgetItem(commandHistory: entry.commands[i].command)
            Divider()
              .frame(height: 1.5)
              .background(Color(UIColor(red: 7/255, green: 191/255, blue: 204/255, alpha: 1.0)))
          }
        }
        .padding(7)
        
      case .systemMedium:
        VStack(alignment: .leading) {
          // TODO: Check if there ara enough commands
          ForEach((0...2), id: \.self) { i in
            BlinkdgetItem(commandHistory: entry.commands[i].command)
            Divider()
              .frame(height: 1.5)
              .background(Color(UIColor(red: 7/255, green: 191/255, blue: 204/255, alpha: 1.0)))
          }
        }
        .padding(7)
        
        
      default:
        VStack(alignment: .leading) {
          ForEach((0...5), id: \.self) { i in
            BlinkdgetItem(commandHistory: entry.commands[i].command)
            Divider()
              .frame(height: 1.5)
              .background(Color(UIColor(red: 7/255, green: 191/255, blue: 204/255, alpha: 1.0)))
            
          }
        }
        .padding(7)
        
      }
      
    }
  }
}


// This defines a Widget, structs that inherits from widget and configures its capabilities
@main
struct Blinkdget: Widget {
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

