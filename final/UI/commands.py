import matlab.engine
eng = matlab.engine.start_matlab()
eng.cd("C:/Users/Samyak Sanghvi/Desktop/podium/")
import matlab.engine
eng = matlab.engine.start_matlab()
eng.cd("C:/Users/Samyak Sanghvi/Desktop/podium/")


lst = [1, 2, 3, 4]
def pick_up(obj):
    """Pick up specified object"""
    print(obj)
    print(lst)
    for i in lst:
        if i == obj or i == int(obj):
            index = lst.index(i)
            break
    else:
        return f"Object {obj} not found"
    print(index)
    eng.pick(index +1, nargout=0)
    lst.remove(index)
    return f"Picked up {obj}"

def stack():
    """Show current stack"""
    eng.drop(nargout=0)
    return "stacked"

def get_list():
    return [1,2,3,4]

def unknown():
    return "unknown"
