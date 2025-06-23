
from flask import Flask, jsonify, request, render_template_string
import threading
import main  # Import your main.py file
import matlab.engine
import commands
eng = matlab.engine.start_matlab()
eng.cd("C:/Users/Samyak Sanghvi/Desktop/podium/")

app = Flask(__name__)

# HTML template

# HTML template
html_template = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Object Control and Voice Command</title>
    <style>
        :root {
            --primary-color: #4a90e2;
            --secondary-color: #2c3e50;
            --accent-color: #27ae60;
            --background-light: #f8f9fa;
            --background-dark: #1a1a1a;
            --text-light: #ffffff;
            --text-dark: #2c3e50;
            --border-radius: 8px;
            --box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background-color: var(--background-light);
            margin: 0;
            display: flex;
            height: 100vh;
            overflow: hidden;
        }

        .left-half {
            width: 50%;
            background: var(--background-dark);
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            border: 20px solid #34495e;
            position: relative;
            box-shadow: var(--box-shadow);
        }

        .left-half h2 {
            position: absolute;
            top: 20px;
            background: var(--primary-color);
            color: var(--text-light);
            padding: 10px 20px;
            border-radius: var(--border-radius);
            font-weight: 600;
            letter-spacing: 1px;
            box-shadow: var(--box-shadow);
        }

        .right-half {
            width: 50%;
            background: var(--text-light);
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 15px;
            overflow-y: auto;
        }

        h2 {
            color: var(--secondary-color);
            font-size: 1.2em;
            margin: 10px 0;
        }

        button {
            background: var(--primary-color);
            color: var(--text-light);
            border: none;
            padding: 8px 16px;
            margin: 5px;
            border-radius: var(--border-radius);
            cursor: pointer;
            transition: all 0.3s ease;
            font-weight: 500;
            box-shadow: var(--box-shadow);
        }

        button:hover {
            background: var(--secondary-color);
            transform: translateY(-2px);
        }

        .spoken-command {
            font-weight: bold;
            color: var(--primary-color);
            margin-top: 10px;
            font-size: 1em;
        }

        #listening-text {
            font-size: 1em;
            font-weight: 600;
            color: var(--accent-color);
            margin-top: 10px;
            display: none;
            animation: pulse 2s infinite;
        }

        .object-list {
            list-style-type: none;
            padding: 0;
            font-size: 1em;
            width: 100%;
            max-width: 400px;
            margin: 0;
        }

        .object-list li {
            margin: 8px 0;
            padding: 8px;
            background: var(--background-light);
            border-radius: var(--border-radius);
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: var(--box-shadow);
        }

        #voice-command-section {
            background: var(--background-light);
            padding: 15px;
            border-radius: var(--border-radius);
            width: 100%;
            max-width: 400px;
            text-align: center;
            box-shadow: var(--box-shadow);
        }

        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }

        #action-buttons button {
            background: var(--accent-color);
            font-size: 1.1em;
            font-weight: 600;
            min-width: 120px;
        }

        #action-buttons button:hover {
            background: #219a52;
        }

        #voice-command-toggle {
            font-size: 0.9em;
            padding: 6px 12px;
        }
    </style>
</head>
<body>
    <div class="left-half">
        <h2>LIVE VIDEO SCREEN</h2>
        <iframe src="http://127.0.0.1:23020/" width="100%" height="100%" frameborder="0" allowfullscreen></iframe>
    </div>
    <div class="right-half">
        <h2>Objects</h2>
        <ul id="object-list" class="object-list"></ul>
        <div id="action-buttons" style="display: flex; gap: 20px;">
            <button onclick="stack()">Stack</button>
        </div>
        <div id="voice-command-section">
            <button id="voice-command-toggle" onclick="toggleVoiceCommand()">Enable Voice Command</button>
            <div id="listening-text">Listening...</div>
        </div>
    </div>

    <script>
        let isVoiceCommandActive = false;

        function toggleVoiceCommand() {
            fetch('/toggle_voice_command', {method: 'POST'})
                .then(response => response.json())
                .then(data => {
                    isVoiceCommandActive = data.status === "enabled";
                    
                    document.getElementById('voice-command-toggle').textContent = 
                        isVoiceCommandActive ? 'Disable Voice Command' : 'Enable Voice Command';

                    document.getElementById('listening-text').style.display = 
                        isVoiceCommandActive ? 'block' : 'none';
                })
                .catch(error => console.error('Error toggling voice command:', error));
        }

        async function getObjectList() {
            const response = await fetch('/get_objects');
            return await response.json();
        }

        async function populateObjects() {
            const objects = await getObjectList();
            const objectList = document.getElementById('object-list');

            objectList.innerHTML = '';

            objects.forEach(obj => {
                objectList.innerHTML += `<li>${obj} <button onclick="pick('${obj}')">Pick Up</button></li>`;
            });
        }

        function pick(obj) {
            fetch('/pick', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({object: obj})
            });
        }

        function stack() {
            fetch('/stack', {method: 'POST'});
        }
        
    

        setInterval(updateRecognizedText, 2000);

        populateObjects();
        setInterval(populateObjects, 5000);
    </script>
</body>
</html>

"""


voice_command_thread = None
is_voice_command_active = False
recognized_text = ""  # ✅ Store recognized text globally

def run_voice_command():
    global recognized_text
    recognized_text = main.main()  # ✅ Assume `main_2.main()` returns recognized speech
    
    # ✅ Print recognized text in the terminal
    print(f"Recognized Text: {recognized_text}")
    # return recognized_text

@app.route('/')
def index():
    return render_template_string(html_template)

@app.route('/toggle_voice_command', methods=['POST'])
def toggle_voice_command():
    global voice_command_thread, is_voice_command_active

    if is_voice_command_active:
        is_voice_command_active = False
        return jsonify({"status": "disabled"})
    else:
        is_voice_command_active = True
        voice_command_thread = threading.Thread(target=run_voice_command)
        voice_command_thread.start()
        return jsonify({"status": "enabled"})

# @app.route('/get_recognized_text', methods=['GET'])  # ✅ New API to get recognized text
# def get_recognized_text():
#     return jsonify({"recognized_text": recognized_text})

@app.route('/get_objects', methods=['GET'])
def get_objects():
    objects = commands.get_list()
    return jsonify(objects)

# def pick_up(obj):
#     """Pick up specified object"""
#     eng.pick(obj, nargout=0)
#     return f"Picked up {obj}"

# def stack():
#     """Show current stack"""
#     eng.drop(nargout=0)
    
# def get_list():
#     """Get list of available objects"""
#     return eng.get_list()

@app.route('/pick', methods=['POST'])
def pick_object():
    obj = request.json['object']
    commands.pick_up(obj)
    return jsonify({"status": "success"})


@app.route('/stack', methods=['POST'])
def stack_objects():
    commands.stack()
    return jsonify({"status": "success"})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)