#!/bin/bash

#Aya AMMAR 
TASK_FILE="tasks.txt"

usage() {
    echo "Usage: $0 [option] [arguments]"
    echo "Options:"
    echo "  -c               Create a new task"
    echo "  -u <id>          Update an existing task"
    echo "  -d <id>          Delete an existing task"
    echo "  -l               List all tasks for today"
    echo "  -s <title>       Search for a task by title"
    exit 1
}

if [ ! -f "$TASK_FILE" ]; then
    touch "$TASK_FILE"
fi

add_task() {
    local task_title="$1"
    local task_description="$2"
    local task_location="$3"
    local task_due_date="$4"
    local task_id=$(uuidgen)  # Generate a unique identifier

    if ! date -d "$task_due_date" &>/dev/null; then
        echo "Error: Invalid date format. Please use 'YYYY-MM-DD HH:MM'" >&2
        return 1
    fi

    echo "$task_id,$task_title,$task_description,$task_location,$task_due_date,false" >> "$TASK_FILE"
    echo "Task created with ID $task_id"
}

modify_task() {
    local task_id="$1"
    
    local temp_task_file=$(mktemp)

    local task_found=false
    while IFS=',' read -r id title description location due_date completed; do
        if [[ "$id" == "$task_id" ]]; then
            task_found=true
            read -p "Enter new title (current: $title): " new_title
            read -p "Enter new description (current: $description): " new_description
            read -p "Enter new location (current: $location): " new_location
            read -p "Enter new due date (YYYY-MM-DD HH:MM, current: $due_date): " new_due_date

            if [[ "$new_due_date" && ! $(date -d "$new_due_date" 2>/dev/null) ]]; then
                echo "Error: Invalid date format. Please use 'YYYY-MM-DD HH:MM'" >&2
                rm "$temp_task_file"
                return 1
            fi

            new_title=${new_title:-$title}
            new_description=${new_description:-$description}
            new_location=${new_location:-$location}
            new_due_date=${new_due_date:-$due_date}

            echo "$id,$new_title,$new_description,$new_location,$new_due_date,$completed" >> "$temp_task_file"
        else
            echo "$id,$title,$description,$location,$due_date,$completed" >> "$temp_task_file"
        fi
    done < "$TASK_FILE"

    if [ "$task_found" = true ]; then
        mv "$temp_task_file" "$TASK_FILE"
        echo "Task with ID $task_id has been updated."
    else
        rm "$temp_task_file"
        echo "Error: Task with ID $task_id not found." >&2
        return 1
    fi
}

remove_task() {
    local task_id="$1"
    local temp_task_file=$(mktemp)
    local task_found=false

    while IFS=',' read -r id title description location due_date completed; do
        if [[ "$id" != "$task_id" ]]; then
            echo "$id,$title,$description,$location,$due_date,$completed" >> "$temp_task_file"
        else
            task_found=true
        fi
    done < "$TASK_FILE"

    if [ "$task_found" = true ]; then
        mv "$temp_task_file" "$TASK_FILE"
        echo "Task with ID $task_id has been deleted."
    else
        rm "$temp_task_file"
        echo "Error: Task with ID $task_id not found." >&2
        return 1
    fi
}

show_today_tasks() {
    local today_date=$(date '+%Y-%m-%d')
    grep "$today_date" "$TASK_FILE" | while IFS=',' read -r id title description location due_date completed; do
        echo "ID: $id"
        echo "Title: $title"
        echo "Due Date: $due_date"
        [[ "$completed" == "true" ]] && status="Completed" || status="Uncompleted"
        echo "Status: $status"
        echo
    done
}

find_task() {
    local task_title="$1"
    grep -i "$task_title" "$TASK_FILE" | while IFS=',' read -r id title description location due_date completed; do
        echo "ID: $id"
        echo "Title: $title"
        echo "Due Date: $due_date"
        [[ "$completed" == "true" ]] && status="Completed" || status="Uncompleted"
        echo "Status: $status"
        echo
    done
}

while getopts ":cu:d:ls:" opt; do
    case $opt in
        c)
            read -p "Enter title: " title
            read -p "Enter description: " description
            read -p "Enter location: " location
            read -p "Enter due date (YYYY-MM-DD HH:MM): " due_date
            add_task "$title" "$description" "$location" "$due_date"
            ;;
        u)
            read -p "Enter ID of the task to update: " task_id
            modify_task "$task_id"
            ;;
        d)
            read -p "Enter ID of the task to delete: " task_id
            remove_task "$task_id"
            ;;
        l)
            show_today_tasks
            ;;
        s)
            read -p "Enter title to search: " search_title
            find_task "$search_title"
            ;;
        \?)
            usage
            ;;
    esac
done

if [ $OPTIND -eq 1 ]; then
    show_today_tasks
fi
