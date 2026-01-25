import os
import time
import logging
import threading
import queue
from pathlib import Path
from comtypes import CoInitialize, CoUninitialize
from comtypes.client import CreateObject

OUTPUT_PATH = os.path.expandvars(r"%APPDATA%\factorio\script-output\factorio-narrator\factorio-narrator-output.txt")
POLL_INTERVAL = 0.05
SAPI_FLAGS_ASYNC_PURGE = 1 | 2

logging.basicConfig(
	level=logging.DEBUG,
	format="%(asctime)s [%(levelname)s] %(message)s",
	datefmt="%H:%M:%S",
)
log = logging.getLogger("FactorioSAPI")

class LineTailer:
	def __init__(self, path: Path, poll_interval: float = 0.05):
		self.path = path
		self.poll = poll_interval
		self._fh = None
		self._pos = 0
		self._buf = ""

	def _open(self):
		if self._fh and not self._fh.closed:
			return
		self.path.parent.mkdir(parents=True, exist_ok=True)
		while True:
			try:
				self._fh = self.path.open("r", encoding="utf-8", errors="ignore")
				self._fh.seek(0, os.SEEK_END)
				self._pos = self._fh.tell()
				log.debug(f"Tailing file: {self.path}")
				return
			except FileNotFoundError:
				time.sleep(self.poll)

	def _reopen_if_rotated(self):
		try:
			size = self.path.stat().st_size
		except FileNotFoundError:
			if self._fh and not self._fh.closed:
				self._fh.close()
				self._fh = None
			self._open()
			return
		if size < self._pos:
			log.warning("File truncated or rotated, reopening...")
			self._fh.close()
			self._fh = self.path.open("r", encoding="utf-8", errors="ignore")
			self._pos = 0

	def lines(self):
		self._open()
		while True:
			self._reopen_if_rotated()
			chunk = self._fh.read()
			if chunk:
				self._pos = self._fh.tell()
				self._buf += chunk
				while True:
					i = self._buf.find("\n")
					if i == -1:
						break
					line = self._buf[:i].rstrip("\r")
					self._buf = self._buf[i + 1 :]
					yield line
			else:
				time.sleep(self.poll)

class SpeakerThread:
	def __init__(self):
		self._q = queue.Queue(maxsize=1)
		self._stop = threading.Event()
		self._thread = threading.Thread(target=self._run, name="SapiSpeaker", daemon=True)
		self._thread.start()

	def speak_latest(self, text: str):
		while not self._q.empty():
			try:
				self._q.get_nowait()
			except queue.Empty:
				break
		self._q.put_nowait(text)

	def stop(self):
		self._stop.set()
		try:
			self._q.put_nowait(None)
		except queue.Full:
			pass
		self._thread.join(timeout=1.0)

	def _run(self):
		CoInitialize()
		try:
			voice = CreateObject("SAPI.SpVoice")
			while not self._stop.is_set():
				text = self._q.get()
				if text is None:
					break
				if not text.strip():
					continue
				log.info(f"Speaking: {text}")
				voice.Speak(text, SAPI_FLAGS_ASYNC_PURGE)
		finally:
			CoUninitialize()

def main():
	speaker = SpeakerThread()
	tailer = LineTailer(Path(OUTPUT_PATH), poll_interval=POLL_INTERVAL)
	try:
		for line in tailer.lines():
			log.debug(f"New line: {line}")
			speaker.speak_latest(line)
	except KeyboardInterrupt:
		log.info("Stopped by user.")
	finally:
		speaker.stop()

if __name__ == "__main__":
	main()
