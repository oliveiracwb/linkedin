# https://github.com/oliveiracwb/linkedin/edit/master/jokenpo/main.py
# Reconhecimento de gestos com Visão Computacional
# https://www.linkedin.com/in/israeloliveira2035/

import cv2
import numpy as np
import math

cap = cv2.VideoCapture("0")
while(cap.isOpened()):
    ret, img = cap.read()

    cv2.rectangle(img, (300,300), (100,100), (0,255,0),0)
    crop_img = img[100:300, 100:300]

    grey = cv2.cvtColor(crop_img, cv2.COLOR_BGR2GRAY)

    k_size = (35, 35)
    filtro_blur = cv2.GaussianBlur(grey, k_size, 0)

    _, thresh1 = cv2.threshold(filtro_blur, 127, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

    image, contours, hierarchy = cv2.findContours(thresh1.copy(), \
           cv2.RETR_TREE, cv2.CHAIN_APPROX_NONE)

    cnt = max(contours, key = lambda x: cv2.contourArea(x))

    x, y, w, h = cv2.boundingRect(cnt)
    cv2.rectangle(crop_img, (x, y), (x+w, y+h), (0, 0, 255), 0)

    hull = cv2.convexHull(cnt)

    drawing = np.zeros(crop_img.shape,np.uint8)
    cv2.drawContours(drawing, [cnt], 0, (0, 255, 0), 0)
    cv2.drawContours(drawing, [hull], 0,(0, 0, 255), 0)

    hull = cv2.convexHull(cnt, returnPoints=False)

    defects = cv2.convexityDefects(cnt, hull)
    count_defects = 0
    cv2.drawContours(thresh1, contours, -1, (0, 255, 0), 3)

    for i in range(defects.shape[0]):
        s,e,f,d = defects[i,0]

        start = tuple(cnt[s][0])
        end = tuple(cnt[e][0])
        far = tuple(cnt[f][0])

        # comprimento de todos os lados do triângulo
        a = math.sqrt((end[0] - start[0])**2 + (end[1] - start[1])**2)
        b = math.sqrt((far[0] - start[0])**2 + (far[1] - start[1])**2)
        c = math.sqrt((end[0] - far[0])**2 + (end[1] - far[1])**2)

        # regra do cosceno
        angle = math.acos((b**2 + c**2 - a**2)/(2*b*c)) * 57

        # ignora angulos menores que 90
        if angle <= 90:
            count_defects += 1
            cv2.circle(crop_img, far, 1, [0,0,255], -1)
        count_large = 0

    if count_defects == 1:
        cv2.putText(img, "TESOURA", (45, 45), cv2.FONT_HERSHEY_SIMPLEX, 2, 2)
    elif count_defects == 2:
        cv2.putText(img, "TILT (3)", (5, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, 2)
    elif count_defects == 3:
        cv2.putText(img, "TILT (4)", (45, 45), cv2.FONT_HERSHEY_SIMPLEX, 2, 2)
    elif count_defects == 4:
        cv2.putText(img, "PAPEL", (45, 45), cv2.FONT_HERSHEY_SIMPLEX, 2, 2)
    else:
        cv2.putText(img,"PEDRA", (45, 45),\
                    cv2.FONT_HERSHEY_SIMPLEX, 2, 2)

    # Mostra a janela processada
    cv2.imshow('Pedra Papel e Tesoura', img)
    all_img = np.hstack((drawing, crop_img))
    cv2.imshow('Contornos', all_img)

    k = cv2.waitKey(10)
    if k == 27:
        break
