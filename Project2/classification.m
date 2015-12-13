clear;clc;
%get classification vectors
VARm = [480.364 801.4593 1.485e3 1.8991e3 520.3670 1.0589e3 2.475e3...
    1.0956e3 3.2548e3 1.0280e3 606.4708 67.1205 1.7991e3 1.2954e3];

MEANm = [-4.0092 -13.3986 16.1774 -13.6166 15.4945 23.9955 -11.1266...
    11.4183 -4.7598 -4.7315, 0.0459 -7.1776 1.5959 3.9563];

VARf = [5.5690e3 3.1736e3 824.7714 1.0764e3 1.8198e3 3.3274e3];

MEANf = [25.8136 11.7280 23.9641 7.4675 14.3271 22.8061];

Male1 = mean(MEANm);
Male2 = mean(VARm);

Female1 = mean(MEANf);
Female2 = mean(VARf);


%generate a line for classification
%change in x
dx1 = Female1-Male1;
dx2 = Female2-Male2;

%find the midpoints
mid1 = (Female1+Male1)/2;
mid2 = (Female2+Male2)/2;

%we want the range to be 100 [-50 50]
m1 = 100/dx1;
m2 = 100/dx2;
x1 = linspace(Male1-5,Female1+5, 1000);
x2 = linspace(Male2-5e3,Female2+5e3, 10000);
for i = 1:length(x1)
    if ((x1(i)>=Male1)&&(x1(i)<=Female1))
        y1(i) = m1.*(x1(i)-mid1);
    elseif x1(i)<Male1
        y1(i) = -50;
    else
        y1(i) = 50;
    end
end
    
    
y2 = m2.*(x2-mid2);

figure(2)
plot(x1,y1)
ylim([-55 55])
title('Concentration Classifier')
ylabel('Confidence Level Male/Female (%)')
xlabel('Difference of Means')
figure(3)
plot(x2,y2)