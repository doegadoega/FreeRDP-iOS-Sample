#!/usr/bin/env python3
"""
タスク管理ヘルパースクリプト
TODO.mdファイルの操作を支援
"""

import re
import sys
from datetime import datetime
from pathlib import Path

class TaskManager:
    def __init__(self, todo_file="docs/TODO.md"):
        self.todo_file = Path(todo_file)
        
    def add_task(self, title, priority, assignee, deadline, description):
        """新しいタスクを追加"""
        priority_emoji = {
            'critical': '🔴',
            'high': '🟠', 
            'medium-high': '🟡',
            'medium': '🟢',
            'low': '🔵'
        }
        
        emoji = priority_emoji.get(priority, '🟢')
        
        new_task = f"""
### [番号]. {title} {emoji}
- **優先度**: {emoji} {priority}
- **担当**: {assignee}
- **期限**: {deadline}
- **状況**: {description}
- **次のアクション**:
  - [ ] [アクション項目を追加してください]
"""
        
        print(f"新しいタスクテンプレート:")
        print(new_task)
        return new_task
    
    def complete_task(self, task_title):
        """タスクを完了済みに移動"""
        if not self.todo_file.exists():
            print(f"Error: {self.todo_file} が見つかりません")
            return False
            
        with open(self.todo_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # タスクを検索
        task_pattern = f"### .*{re.escape(task_title)}.*"
        if not re.search(task_pattern, content):
            print(f"Warning: タスク '{task_title}' が見つかりませんでした")
            return False
        
        print(f"タスク '{task_title}' を完了済みに移動する処理を実装してください")
        return True
    
    def show_priority_tasks(self, priority="🔴"):
        """指定優先度のタスクを表示"""
        if not self.todo_file.exists():
            print(f"Error: {self.todo_file} が見つかりません")
            return
            
        with open(self.todo_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 優先度でフィルタ
        lines = content.split('\n')
        in_priority_section = False
        for line in lines:
            if f"**優先度**: {priority}" in line:
                in_priority_section = True
            elif line.startswith("###") and in_priority_section:
                in_priority_section = False
            
            if in_priority_section or (line.startswith("###") and priority in line):
                print(line)
    
    def update_timestamp(self):
        """ファイルのタイムスタンプを更新"""
        if not self.todo_file.exists():
            return
        
        with open(self.todo_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # タイムスタンプを更新
        now = datetime.now().strftime("%Y/%m/%d %H:%M")
        content = re.sub(
            r'\*\*最終更新\*\*: .*',
            f'**最終更新**: {now}',
            content
        )
        
        with open(self.todo_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"TODO.md のタイムスタンプを更新しました: {now}")

def main():
    manager = TaskManager()
    
    if len(sys.argv) < 2:
        print("使用方法:")
        print("  python task-manager.py add <title> <priority> <assignee> <deadline> <description>")
        print("  python task-manager.py complete <title>")
        print("  python task-manager.py show <priority>")
        print("  python task-manager.py update-time")
        print("")
        print("優先度: critical, high, medium-high, medium, low")
        return
    
    command = sys.argv[1]
    
    if command == "add" and len(sys.argv) >= 7:
        title = sys.argv[2]
        priority = sys.argv[3]
        assignee = sys.argv[4] 
        deadline = sys.argv[5]
        description = ' '.join(sys.argv[6:])
        manager.add_task(title, priority, assignee, deadline, description)
        
    elif command == "complete" and len(sys.argv) >= 3:
        task_title = ' '.join(sys.argv[2:])
        manager.complete_task(task_title)
        
    elif command == "show" and len(sys.argv) >= 3:
        priority_map = {
            'critical': '🔴',
            'high': '🟠',
            'medium-high': '🟡', 
            'medium': '🟢',
            'low': '🔵'
        }
        priority = priority_map.get(sys.argv[2], sys.argv[2])
        manager.show_priority_tasks(priority)
        
    elif command == "update-time":
        manager.update_timestamp()
        
    else:
        print("無効なコマンドです")

if __name__ == "__main__":
    main() 