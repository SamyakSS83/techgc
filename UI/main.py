import os
import re
import ast
import json
import commands  # commands.py contains get_list() and pick_up(obj)
import whisper
import torch
import numpy as np
from groq import Groq  # Assumes installation of the groq package and GROQ_API_KEY set in the environment
import pyaudio
import wave
import tempfile

def transcribe_audio():
    """
    Captures audio from the microphone using PyAudio and transcribes it 
    into text using the Whisper model for improved speech recognition.
    Returns the recognized text or an empty string if transcription fails.
    """
    try:
        # Set up PyAudio for recording
        CHUNK = 1024
        FORMAT = pyaudio.paInt16
        CHANNELS = 1
        RATE = 16000
        RECORD_SECONDS = 5  # Adjustable recording duration
        
        # Create a temporary WAV file to store the recording
        temp_file = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
        temp_filename = temp_file.name
        temp_file.close()
        
        # Start recording
        p = pyaudio.PyAudio()
        stream = p.open(format=FORMAT,
                        channels=CHANNELS,
                        rate=RATE,
                        input=True,
                        frames_per_buffer=CHUNK)
        
        print("Please speak now...")
        frames = []
        
        # Record for the specified duration
        for _ in range(0, int(RATE / CHUNK * RECORD_SECONDS)):
            data = stream.read(CHUNK, exception_on_overflow=False)
            frames.append(data)
        
        print("Recording finished")
        
        # Stop recording
        stream.stop_stream()
        stream.close()
        p.terminate()
        
        # Save recording to temporary WAV file
        with wave.open(temp_filename, 'wb') as wf:
            wf.setnchannels(CHANNELS)
            wf.setsampwidth(p.get_sample_size(FORMAT))
            wf.setframerate(RATE)
            wf.writeframes(b''.join(frames))
        
        # Load Whisper model (using "tiny" for speed, can use "base" or "small" for better accuracy)
        model = whisper.load_model("tiny")
        
        # Transcribe the audio file
        result = model.transcribe(temp_filename)
        text = result["text"].strip()
        
        # Clean up the temporary file
        os.unlink(temp_filename)
        
        print("Transcribed text:", text)
        return text
    
    except Exception as e:
        print("An error occurred during transcription:", e)
        return ""

def convert_to_command(transcribed_text):
    # Retrieve valid objects from commands.py
    valid_objects = commands.get_list()
    client = Groq(api_key="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")
    prompt = (
        "Convert the following instruction into a valid command in JSON format. "
        "Choose between these two commands:\n\n"
        "1. pick_up(object) - where object must be one of: " + str(valid_objects) + "\n"
        "2. stack() - with no arguments\n\n"
        "3. unknown() - with no arguments for unknown commands\n\n"
        "if you are not sure about what the command is, and you are not sure then return the command as 'unknown', for gibberish and unrelated commands you must return this"
        "For the transcribed text below, return a JSON object with a 'command' field "
        "containing the exact function call as a string (e.g. {'command': 'pick_up(\"object1\")'})\n\n"
        "Transcribed text: " + transcribed_text
    )
    response = client.chat.completions.create(
        messages=[
            {
                "role": "system", 
                "content": "Convert instructions into JSON containing either pick_up() or stack() commands. Always include the command in a JSON response with format: {'command': 'function_call'}"
            },
            {"role": "user", "content": prompt}
        ],
        model="mixtral-8x7b-32768",
        temperature=0.2,
        max_tokens=100,
        stream=False,
        response_format={"type": "json_object"}
    )
    
    response_json = json.loads(response.choices[0].message.content)
    command_str = response_json.get('command', '')
    return command_str


def run_command(command_str):
    """
    Safely parses the LLM output and executes the corresponding function from commands.py.
    Handles both pick_up() and stack() commands.
    """
    if not command_str:
        print("Empty command received")
        return
        
    match = re.match(r'(\w+)\((.*)\)', command_str)
    if not match:
        print("Invalid command format:", command_str)
        return
        
    func_name = match.group(1)
    args_str = match.group(2).strip()

    # Allow both pick_up and stack commands
    commands_map = {
        "pick_up": commands.pick_up,
        "stack": commands.stack,
        "unknown": commands.unknown
    }
    
    if func_name not in commands_map:
        print("Unknown command. Must be either pick_up() or stack()")
        return

    # Handle arguments based on command type
    if func_name == "stack":
        if args_str:
            print("stack() command doesn't accept arguments")
            return
        result = commands_map[func_name]()
    else:  # pick_up command
        try:
            arg_value = ast.literal_eval(args_str) if args_str else None
            if not arg_value:
                print("Missing argument for pick_up")
                return
            if arg_value not in commands.get_list():
                print("Invalid object. Must be one of:", commands.get_list())
                return
            result = commands_map[func_name](arg_value)
        except Exception as e:
            print("Failed to parse arguments:", args_str, e)
            return

    # print("Command result:", result)

def main():
    transcribed_text = transcribe_audio()
    print("Transcribed text:", transcribed_text)
    
    command_str = convert_to_command(transcribed_text)
    print("Converted command:", command_str)
    
    run_command(command_str)
    return command_str

if __name__ == "__main__":
    main()