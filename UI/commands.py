import matlab.engine
eng = matlab.engine.start_matlab()
eng.cd("D:/techgc/final/Instant-GPD")
import matlab.engine
eng = matlab.engine.start_matlab()
eng.cd("D:/techgc/final/Instant-GPD")

global current 

lst = [1, 2, 3, 4]
picked_up = set()
available = [1, 2, 3, 4]
def pick_up(obj):
    """Pick up specified object"""
    print(obj)
    index = lst.index(obj)
    eng.pick(index +1, nargout=0)
    available.remove(obj)
    picked_up.add(obj)
    global current
    current = obj
    return f"Picked up {obj}"

def stack():
    """Show current stack"""
    eng.drop(nargout=0)
    return "stacked"

def get_list():
    return [1,2,3,4]

def get_current():
    return current

def get_picked():
    return picked_up

def get_available():
    return available

def unknown():
    return "unknown"
