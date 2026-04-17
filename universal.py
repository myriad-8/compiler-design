import os
import sys
import subprocess

def run():
    if len(sys.argv) < 2:
        print("Usage: expresso <filename.exp>")
        return

    input_file = sys.argv[1]
    cwd = os.getcwd()
    image_name = "ghcr.io/myriad-8/compiler-design/expresso:latest"

    # We removed 'bash -c' and 'clang'. 
    # This just runs your compiler and shows EVERYTHING it prints.
    command = [
        "docker", "run", "--rm",
        "-v", f"{cwd}:/src",
        image_name,
        "/app/expresso_compiler", f"/src/{input_file}"
    ]

    try:
        # This keeps the output visible in your terminal
        subprocess.run(command, check=True)
    except Exception as e:
        print(f" Error: {e}")

if __name__ == "__main__":
    run()