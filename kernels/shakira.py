import  cv2
import  numpy as np

img = cv2.imread('shakira.png')
height = img.shape[0]
width = img.shape[1]
channels = img.shape[2]

'''for ch in range(img.shape[2]):
    for col in range(img.shape[0]):
        for lin in range(img.shape[1]):
            print(col, lin, ch)
            print (img[lin,col,ch])
    print ('\n')
'''
magnification = 8

cv2.imshow('ORIGINAL' , img )
# cv2.imwrite('c:/imgs/original.png', img)

resize_img = cv2.resize(img  , (int(img.shape[1] * magnification), int(img.shape[0] * magnification)), interpolation = cv2.INTER_AREA)
cv2.imshow('Nenhum' , resize_img )
# cv2.imwrite('c:/imgs/Nenhum.png', resize_img)

resize_img = cv2.resize(img  , (int(img.shape[1] * magnification), int(img.shape[0] * magnification)), interpolation = cv2.INTER_CUBIC)
cv2.imshow('Cubica' , resize_img )
# cv2.imwrite('c:/imgs/Cubica.png', resize_img)

resize_img = cv2.resize(img  , (int(img.shape[1] * magnification), int(img.shape[0] * magnification)), interpolation = cv2.INTER_LINEAR)
cv2.imshow('Linear' , resize_img )
# cv2.imwrite('c:/imgs/Linear.png', resize_img)

median = cv2.medianBlur(resize_img,3)
cv2.imshow('media' , median )
# cv2.imwrite('c:/imgs/median.png', median)

blur = cv2.GaussianBlur(resize_img,(3,5),0)
cv2.imshow('DesfoqueGaussiano' , blur )
# cv2.imwrite('c:/imgs/DesfoqueGaussiano.png', blur)

blur2 = cv2.bilateralFilter(resize_img,9,75,75)
cv2.imshow('Desfoque Bilateral' , blur2 )
# cv2.imwrite('c:/imgs/DesfoqueBilateral.png', blur2)

kernel = np.ones((5,5),np.uint8)
erosion = cv2.erode(resize_img,kernel,iterations = 3)
cv2.imshow('Erosao' , erosion )
# cv2.imwrite('c:/imgs/erosion.png', erosion)

dilation = cv2.dilate(erosion,kernel,iterations = 3)
cv2.imshow('Dilatacao' , dilation )
# cv2.imwrite('c:/imgs/dilation.png', dilation)

opening = cv2.morphologyEx(resize_img, cv2.MORPH_OPEN, kernel)
cv2.imshow('Abertura' , opening )
# cv2.imwrite('c:/imgs/opening.png', opening)

closing = cv2.morphologyEx(resize_img, cv2.MORPH_CLOSE, kernel)
cv2.imshow('Fechamento' , closing )
# cv2.imwrite('c:/imgs/closing.png', closing)

gradient = cv2.morphologyEx(resize_img, cv2.MORPH_GRADIENT, kernel)
cv2.imshow('Gradiente' , gradient )
# cv2.imwrite('c:/imgs/gradient.png', gradient)

laplacian = cv2.Laplacian(resize_img,cv2.CV_64F)
cv2.imshow('Laplaciana' , laplacian )
# cv2.imwrite('c:/imgs/laplacian.png', laplacian)

edges = cv2.Canny(resize_img,15,25)
cv2.imshow('Cantos' , edges )
# cv2.imwrite('c:/imgs/edges.png', edges)

kernel = np.array([[-1,-1,-1],
                   [-1, 9,-1],
                   [-1,-1,-1]])
sharpened = cv2.filter2D(resize_img, -1, kernel) # applying the sharpening kernel to the input image & displaying it
cv2.imshow('Afiacao / sharpen' , sharpened )
# cv2.imwrite('c:/imgs/sharpened.png', sharpened)

imgray = cv2.cvtColor(resize_img,cv2.COLOR_BGR2GRAY)
ret,thresh = cv2.threshold(imgray,127,255,0)
image, contours, hierarchy = cv2.findContours(thresh,cv2.RETR_TREE,cv2.CHAIN_APPROX_SIMPLE)
cv2.imshow('Contornos' , image )
# cv2.imwrite('c:/imgs/Contornos.png', image)

while True:
  if cv2.waitKey(0):
    cv2.destroyAllWindows()
    print('sair')
    break
