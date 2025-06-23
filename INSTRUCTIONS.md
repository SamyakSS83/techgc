# ECA Sort: Robotics PS2

## Introduction
This project implements a robotic system that picks, manipulates, and stacks both regular and irregular objects using computer vision for object identification.

## Project Structure
- **Regular Object Picking and Stacking**: `final/Instant-GPD/R13`
- **Irregular Object Picking and Manipulation**: `final/irreg/R14`
- **Predefined Path Execution**: `final/path_execution`
- **User Interface**: `final/UI`

## Setup Instructions

### Prerequisites
- CoppeliaSim simulation environment
- MATLAB with required toolboxes
- Kinect camera setup
- ffmpeg (for UI functionality)

## Usage Instructions

### Regular Object Picking and Stacking

#### Initial Setup
1. Rename your target object from `Cuboid3` to `Cuboid1` in CoppeliaSim
2. Navigate to the Kinect camera hierarchy
3. Locate the "glass" component
4. Uncheck the following properties:
   - Collidable
   - Measurable
   - Detectable
5. Open the project folder in MATLAB

#### Single Object Operation
1. In MATLAB terminal, run:
   ```matlab
   pick(1)
   ```
2. Once the object is picked, execute:
   ```matlab
   drop()
   ```
   This will stack the object at the designated location.

#### Multiple Object Operation
1. Place multiple regular objects in the scene
2. Name them sequentially: `Cuboid1`, `Cuboid2`, ..., `Cuboid{n}`
3. To pick the i-th object, run:
   ```matlab
   pick(i)
   ```
4. To stack the object on top of others, run:
   ```matlab
   drop()
   ```

### Irregular Object Picking

#### Setup and Execution
1. Rename your irregular object (e.g., `Cup`) to `Cuboid1`
2. Run the CoppeliaSim script
3. In MATLAB, execute:
   ```matlab
   pick(1)
   ```

**Note**: If the program returns an error, try running the command again. Finding valid paths from a large set of possible paths is computationally intensive and may occasionally fail on the first attempt.

### Predefined Path Execution

To use predefined paths:
1. Copy the provided LUA code
2. Paste it into a new script in CoppeliaSim with the robot spawned
3. Run the simulation to observe the predefined path execution

### User Interface Options

#### Graphical User Interface (GUI)
```bash
python ./UI/scripts.py
```

#### Command Line Interface (CLI)
```bash
python ./UI/terminal.py
```

**Important**: Ensure ffmpeg is installed on your system before running the UI components.

## Troubleshooting

- **Irregular picking errors**: This is normal due to the computational complexity of path planning. Simply retry the command.
- **Object naming**: Ensure objects are named exactly as specified (`Cuboid1`, `Cuboid2`, etc.)
- **Kinect setup**: Verify that the glass component properties are correctly unchecked
- **Dependencies**: Confirm all required software (MATLAB, CoppeliaSim, ffmpeg) is properly installed

## File Structure
```
final/
├── Instant-GPD/R13/     # Regular object handling
├── irreg/R14/           # Irregular object handling  
├── path_execution/      # Predefined path scripts
└── UI/                  # User interface components
    ├── scripts.py       # GUI application
    └── terminal.py      # CLI application
```
