echo "Enter the path of the directory you want to monitor:"
read path

echo "The path you entered is: ${path}"

echo "Enter the regular expression you want to match:"
read regular_expression

#regular_expression='^(input|log)_[1-9]|[1][0-9]|\.txt$'

if  [[ $regular_expression =~ ^.*\.(txt)$  ]]; then
	    echo "Valid input"
    else
	        echo "Invalid input: File name does not match the pattern"
		    exit 1
fi

# Function to execute when a file change is detected
function file_changed() {
	echo "Changed file: $1"
	        head -n 1 "$1"    
    # Search for the specific string in the file
    if grep -q "specific string" "$1"; then
        # Extract values from the line containing the string using awk
        value1=$(grep "specific string" "$1" | awk '{print $1}')
        value2=$(grep "specific string" "$1" | awk '{print $2}')
        
        # Do something with the extracted values
        echo "Value 1: $value1"
        echo "Value 2: $value2"
    fi
    
    # Create a backup of the file
    backup_dir="backup"
    mkdir -p "$backup_dir"
    cp "$1" "$backup_dir"


	input_dir="$1"
    output_dir="$2"
    logs_dir="$3"
    pattern="$4"
    sample_line="$5"
    processed_line="$6"
    
    # Check that input directory exists and is readable
    if [ ! -d "$input_dir" ] || [ ! -r "$input_dir" ]; then
        echo "Error: input directory not found or not readable"
        exit 1
    fi
    
    # Check that output directory exists and is writable
    if [ ! -d "$output_dir" ] || [ ! -w "$output_dir" ]; then
        echo "Error: output directory not found or not writable"
        exit 1
    fi
    
    # Check that logs directory exists and is writable
    if [ ! -d "$logs_dir" ] || [ ! -w "$logs_dir" ]; then
        echo "Error: logs directory not found or not writable"
        exit 1
    fi
    
    # Check that pattern is valid
    if [[ ! "$pattern" =~ ^.*\.(txt)$ ]]; then
        echo "Error: invalid regular expression pattern"
        exit 1
    fi
    
    # Search for files that match pattern
    files=$(find "$input_dir" -type f -name "$pattern")
    
    # If no files found, print message and exit
    if [ -z "$files" ]; then
        echo "No files found matching pattern $pattern"
        exit 0
    fi
    
    for file in $files; do
        echo "Processing file: $file"
        
        # Search for sample line in file
        if grep -q "$sample_line" "$file"; then
            # Replace sample line with processed line using sed
            sed -i "s/$sample_line/$processed_line/g" "$file"
            
            # Write modified file to output directory
            filename=$(basename "$file")
            cp "$file" "$output_dir/$filename"
            
            # Create log file in logs directory with timestamp
            timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
            log_file="$logs_dir/$filename-$timestamp.log"
            echo "Processing completed on $(date)" > "$log_file"
        else
            echo "Sample line not found in file: $file"
        fi
    done
	}

	# Monitor the directory for changes and execute the file_changed function when a change is detected
	inotifywait -m -r -e modify,create,delete --format '%w%f' "$path" | grep --line-buffered "$regular_expression" | while read -r changed_file; do
	    file_changed "$changed_file"
	    sleep 1
    done

