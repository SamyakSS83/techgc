import main
import threading
from colorama import init, Fore, Style
import sys
import commands
# import matlab.engine
# eng = matlab.engine.start_matlab()
# eng.cd("C:/Users/Samyak Sanghvi/Desktop/podium/")


# lst = [1, 2, 3, 4]
# def pick_up(obj):
#     """Pick up specified object"""
#     print(obj)
#     print(lst)
#     for i in lst:
#         if i == obj or i == int(obj):
#             index = lst.index(i)
#             break
#     else:
#         return f"Object {obj} not found"
#     print(index)
#     eng.pick(index +1, nargout=0)
#     lst.remove(index)
#     return f"Picked up {obj}"

# def stack():
#     """Show current stack"""
#     eng.drop(nargout=0)

# def get_list():
#     return [1,2,3,4]

def help():
    """Display available commands and their descriptions"""
    print(Fore.GREEN + "\nAvailable Commands:" + Style.RESET_ALL)
    print(Fore.CYAN + "  help()          " + Fore.WHITE + "- Show this help message")
    print(Fore.CYAN + "  get_list()        " + Fore.WHITE + "- Get list of available objects")
    print(Fore.CYAN + "  pick_up(obj)    " + Fore.WHITE + "- Pick up specified object")
    print(Fore.CYAN + "  stack()         " + Fore.WHITE + "- Stack picked object")
    print(Fore.CYAN + "  get_current()   " + Fore.WHITE + "- Get current object")
    print(Fore.CYAN + "  get_picked()    " + Fore.WHITE + "- Get picked objects")
    print(Fore.CYAN + "  get_available() " + Fore.WHITE + "- Get available objects")
    print(Fore.CYAN + "  take_from_speech" + Fore.WHITE + "- Listen for voice commands")
    print(Fore.CYAN + "  q, Q, exit      " + Fore.WHITE + "- Exit the program\n" + Style.RESET_ALL)

def main_loop():
    init()  # Initialize colorama for Windows color support
    print(Fore.YELLOW + "Welcome to the Command Interface!")
    print("Type 'help()' for available commands" + Style.RESET_ALL)
    
    while True:
        try:
            user_input = input(Fore.BLUE + ">> " + Style.RESET_ALL).strip()
            
            if user_input.lower() in ['q', 'exit']:
                print(Fore.YELLOW + "Goodbye!" + Style.RESET_ALL)
                break
                
            elif user_input == 'help()':
                help()
                
            elif user_input == 'get_list()':
                result = commands.get_list()
                print(Fore.GREEN + str(result) + Style.RESET_ALL)
                
            elif user_input.startswith('pick_up('):
                obj = user_input[8:-1]  # Extract object name from pick_up(obj)
                arg = int(obj)
                result = commands.pick_up(arg)
                print(Fore.GREEN + str(result) + Style.RESET_ALL)
                
            elif user_input == 'stack()':
                result = commands.stack()
                print(Fore.GREEN + str(result) + Style.RESET_ALL)
                
            elif user_input == 'get_current()':
                result = commands.get_current()
                print(Fore.GREEN + str(result) + Style.RESET_ALL)
                
            elif user_input == 'get_picked()':
                result = commands.get_picked()
                print(Fore.GREEN + str(result) + Style.RESET_ALL)
                
            elif user_input == 'get_available()':
                result = commands.get_available()
                print(Fore.GREEN + str(result) + Style.RESET_ALL)
                
            elif user_input == 'take_from_speech':
                print(Fore.YELLOW + "Listening for speech input..." + Style.RESET_ALL)
                result = main.main()
                print(Fore.GREEN + f"Speech result: {result}" + Style.RESET_ALL)
                
            else:
                print(Fore.RED + "Unknown command. Type 'help()' for available commands." + Style.RESET_ALL)
                
        except Exception as e:
            print(Fore.RED + f"Error: {str(e)}" + Style.RESET_ALL)

if __name__ == "__main__":
    main_loop()