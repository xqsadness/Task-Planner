//
//  Home.swift
//  TaskManagement
//
//  Created by xqsadness on 30/07/2024.
//

import SwiftUI
import SwiftData

struct Home: View {
    
    //view props
    @State private var currentDay: Date = .init()
    @State private var addNewTask: Bool = false
    @State private var selectedTask: Task?
    @State private var taskDate: Date = .init()
    // SwiftData query to fetch tasks
    @Query var tasks: [Task]
    @Environment(\.modelContext) private var context
    
    var body: some View {
        ScrollView{
            TimelineView()
                .padding([.horizontal, .bottom], 15)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) {
            HeaderWeekSlider(currentDate: $currentDay, addNewTask: $addNewTask)
        }
        .fullScreenCover(isPresented: $addNewTask){
            AddTaskView(taskDate: $taskDate)
        }
        .sheet(item: $selectedTask) { task in
            DetailTask(task: task)
        }
    }
    
    //Timeline view
    @ViewBuilder
    func TimelineView() -> some View{
        ScrollViewReader{ proxy in
            let hours = Calendar.current.hour
            let midHour = hours[hours.count / 2]
            VStack{
                let hours = Calendar.current.hour
                
                ForEach(hours, id: \.self){ hour in
                    TimelineViewRow(hour)
                        .id(hour)
                }
            }
            .onAppear{
                proxy.scrollTo(midHour)
            }
        }
    }
    //Timeline view row
    @ViewBuilder
    func TimelineViewRow(_ date: Date) -> some View{
        HStack(alignment: .top){
            Text(date.toString("h a"))
                .ubuntu(14, weight: .regular)
                .frame(width: 45, alignment: .leading)
                .onTapGesture {
                    taskDate = date
                    addNewTask = true
                }
            
            //Filtering tasks
            let calendar = Calendar.current
            let filteredTasks = tasks.filter{
                if let hour = calendar.dateComponents([.hour], from: date).hour,
                   let taskHour = calendar.dateComponents([.hour], from: $0.dateAdded).hour,
                   hour == taskHour && calendar.isDate($0.dateAdded, inSameDayAs: currentDay){
                    return true
                }
                return false
            }
            
            if filteredTasks.isEmpty{
                Rectangle()
                    .stroke(.gray.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, lineCap: .butt, lineJoin: .bevel, dash: [5], dashPhase: 5))
                    .frame(height: 0.5)
                    .offset(y: 10)
                    .contentShape(.rect)
                    .onTapGesture {
                        taskDate = date
                        addNewTask = true
                    }
            }else{
                //Task view
                VStack(spacing: 10){
                    ForEach(filteredTasks){ task in
                        TaskRow(task)
                    }
                }
                .animation(.spring, value: filteredTasks.count)
            }
        }
        .hAlign(.leading)
        .padding(.vertical, 15)
    }
    
    //Task row
    @ViewBuilder
    func TaskRow(_ task: Task) -> some View{
        HStack{
            VStack(alignment: .leading, spacing: 8){
                Text(task.taskName.uppercased())
                    .ubuntu(16, weight: .bold)
                    .foregroundStyle(task.taskCategory.color)
                    .strikethrough(task.isCompleted, color: task.taskCategory.color)
                
                if !task.taskDescription.isEmpty{
                    Text(task.taskDescription)
                        .ubuntu(14, weight: .light)
                        .foregroundStyle(task.taskCategory.color.opacity(0.8))
                        .strikethrough(task.isCompleted, color: task.taskCategory.color)
                }
            }
            .hAlign(.leading)
            
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .imageScale(.large)
                .foregroundStyle(task.taskCategory.color)
                .contentTransition(.symbolEffect(.replace))
                .onTapGesture {
                    withAnimation {
                        task.isCompleted.toggle()
                    }
                    
                    if !task.isCompleted{
                        NotificationService.shared.cancelNotification(for: task)
                    }
                }
        }
        .hAlign(.leading)
        .padding(12)
        .background{
            ZStack(alignment: .leading){
                Rectangle()
                    .fill(task.taskCategory.color)
                    .frame(width: 4)
                
                Rectangle()
                    .fill(task.taskCategory.color.opacity(0.25))
            }
        }
        .opacity(task.isCompleted ? 0.35 : 1)
        .contentShape(.rect)
        .onTapGesture {
            selectedTask = task
        }
        .contextMenu{
            Button(role: .destructive) {
                context.delete(task)
                NotificationService.shared.cancelNotification(for: task)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

#Preview {
    Home()
}
