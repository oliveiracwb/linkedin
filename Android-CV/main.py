# coding=utf-8
# qpy:kivy

import kivy
import time
from kivy.app import App
from kivy.clock import Clock
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.floatlayout import FloatLayout
from kivy.factory import Factory
from kivy.properties import ObjectProperty

import os

try:
    import cv2
except:
    from cv import cv2
import numpy as np
from kivy.uix.camera import Camera
from kivy.graphics.texture import Texture

face_cascade = cv2.CascadeClassifier(r"./xml/haarcascade_frontalface_default.xml")
cv2.setUseOptimized(True)
start=False


class LoadDialog(FloatLayout):
    load = ObjectProperty(None)
    cancel = ObjectProperty(None)

class Camera2(Camera):
    firstFrame = None

    def _camera_loaded(self, *largs):
        if kivy.platform == 'android':
            self.texture = Texture.create(size=self.resolution, colorfmt='rgb')
            self.texture_size = list(self.texture.size)
        else:
            super(Camera2, self)._camera_loaded()

    def on_tex(self, *l):
        if kivy.platform == 'android':
            buf = self._camera.grab_frame()
            if not buf:
                return
            frame = self._camera.decode_frame(buf)
            self.image = frame = self.process_frame(frame)
            buf = frame.tostring()
            self.texture.blit_buffer(buf, colorfmt='rgb', bufferfmt='ubyte')
        super(Camera2, self).on_tex(*l)

    def process_frame(self, frame):
        r, g, b = cv2.split(frame)
        frame = cv2.merge((b, g, r))
        rows, cols, channel = frame.shape
        M = cv2.getRotationMatrix2D((cols / 2, rows / 2), 90, 1)
        dst = cv2.warpAffine(frame, M, (cols, rows))
        frame = cv2.flip(dst, 1)
        if self.index == 1:
            frame = cv2.flip(dst, -1)
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(
            gray,
            scaleFactor=2,
            minNeighbors=3,
            minSize=(int(app.root.ids.sizer.text), int(app.root.ids.sizer.text))
        )
        for (x, y, w, h) in faces:
            cv2.rectangle(frame, (x, y), (x + w, y + w), (0, 255, 0), 2)
        return frame


class MyLayout(BoxLayout):
    pass


class MainApp(App):

    def change_haar(self, s):
        if s == "Face (Light Version)":
            filename = "haarcascade_frontalface_default.xml"
        elif s == "Face Frontal":
            filename = "haarcascade_frontalcatface_extended.xml"
        elif s == "Face (Intell)":
            filename = "haarcascade_frontalface_intel.xml"
        elif s == "Olhos":
            filename = "haarcascade_eye.xml"
        elif s == "Olho Esquerdo":
            filename = "haarcascade_lefteye_2splits.xml"
        elif s == "Olho Direito":
            filename = "haarcascade_righteye_2splits.xml"
        elif s == "Oculos":
            filename = "haarcascade_eye_tree_eyeglasses.xml"
        elif s == "Sorriso":
            filename = "haarcascade_smile.xml"
        elif s == "Corpo Todo":
            filename = "haarcascade_fullbody.xml"
        elif s == "Corpo (inferior)":
            filename = "haarcascade_lowerbody.xml"
        elif s == "Corpo (membros superiores)":
            filename = "haarcascade_upperbody.xml"
        elif s == "Placa Veicular (Russa)":
            filename = "haarcascade_licence_plate_rus_16stages.xml"
        elif s == "Placa Veicular (Brazil)":
            filename = "haarcascade_plate_recog_br.xml"
        elif s == "Face de Gatos":
            filename = "haarcascade_cat_facedetector.xml"
        elif s == "Bola Futebol":
            filename = "haarcascade_football_ball.xml"
        elif s == "Armas (Guns)":
            filename = "haarcascade_gun_detector.xml"

        face_cascade = cv2.CascadeClassifier(r"./xml/"+filename)
        cv2.setUseOptimized(True)
        self.root.ids.camera2.play = True
        start = True

    def build(self):
        app.root = MyLayout()
        return MyLayout()

    def on_start(self):
        Clock.schedule_once(self.detect, 10)

    def detect(self, nap):
        if start:
            image = self.root.ids.camera2.image
            rows, cols = image.shape[:2]
            ctime = time.ctime()[11:19]
        Clock.schedule_once(self.detect, 10)

if __name__ == '__main__':
    app = MainApp()
    MainApp().run()
