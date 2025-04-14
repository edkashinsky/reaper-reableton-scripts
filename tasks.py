from invoke import task
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import time
import os

config = {
    "core": [
        "ek_Core functions v1",
        "ek_Core functions GUI"
    ],
    "corebg": [
        "ek_Adaptive grid functions",
        "ek_Core functions startup"
    ],
    "edge_silence_cropper": [
        "ek_Edge silence cropper functions"
    ],
    "smart_renaming": [
        "ek_Smart renaming functions"
    ],
    "smart_split_items": [
        "ek_Smart split items by mouse cursor functions"
    ],
    "snap_items": [
        "ek_Snap items to markers functions"
    ],
    "tracks_collapser": [
        "ek_Tracks collapser functions"
    ],
    "tracks_navigator": [
        "ek_Tracks navigator functions"
    ]
}

class WatchHandler(FileSystemEventHandler):
    def __init__(self, ctx):
        self.ctx = ctx

    def on_modified(self, event):
        if event.src_path.endswith(".lua"):
            print(f"📝 File has changed: {event.src_path}")
            build(self.ctx)


@task
def build(ctx):
    for name, scripts in config.items():
        print(f"Compiling {name}.dat...")

        scripts_string = ""
        for script in scripts:
            scripts_string += f"\"Core/source/{script}.lua\" "

        os.system(f"luac -o Core/data/{name}_5.4.dat {scripts_string}")
        os.system(f"luac53 -o Core/data/{name}_5.3.dat {scripts_string}")

@task
def watch(c):
    path = os.path.join(os.path.abspath("."), "Core", "source")
    event_handler = WatchHandler(c)
    observer = Observer()
    observer.schedule(event_handler, path=path, recursive=True)
    observer.start()
    print(f"👀 Watch for {path}...")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()

    observer.join()