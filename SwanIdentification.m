% MATLAB/Octave script designed to isolate swans from known image set then compare to ground truth to evaluate script performance
% dice() is part of MATLAB but not Octave, so performance evaluation doesn't work in Octave
% Before running in Octave, have to load image package by entering "pkg load image" into command window

clear; close all; clc;

% Do for every file in dataset
results = [];
inputs = dir("Input/*.jpg");
for file = inputs'

  % --- Swan Recognition ---
  % Load input image
  I = imread(fullfile("Input",file.name));
  figure;
  imshow(I);
  title('Load input image');

  % Get greyscale image
  Igray = rgb2gray(I);
  figure;
  imshow(Igray);
  title('Conversion of input image to greyscale');

  % Resizing the grayscale image using bilinear interpolation
  Iresize = imresize(Igray, 0.5, "bilinear");
  figure;
  imshow(Iresize);
  title('Resizing the grayscale image using bilinear interpolation');

  % Sharpen greyscale image
  Iunsharp = imsharpen(Iresize);
  figure;
  imshow(Iunsharp);
  title('unsharp masking');

  % Normalise image contrast (neccessary for threshold)
  j = 255*im2double(Iunsharp); %need double format + more precise
  mini = min(min(j));
  maxi = max(max(j));
  Igray2 = imadjust(Iunsharp,[mini/255; maxi/255],[0.325;0.675]);
  figure;
  imshow(Igray2);
  title('Normalise image contrast');

  % Binarise manipulated image
  bw = im2bw(Igray2, 0.56);
  figure;
  imshow(bw);
  title('Producing binarised image');

  % clear border, fill holes
  bw2 = imclearborder(bw);
  bwfill = imfill(bw2, "holes");
  figure;
  imshow(bwfill);
  title('Remove border components and fill holes');

  % get regions
  up = bwpropfilt(bwfill, "Perimeter", [116,1000]);
  up2 = bwpropfilt(up, "Eccentricity", [0.56,0.77]);
  up3 = bwpropfilt(up2, "Orientation", [-80, -10]);
  upFinal = bwpropfilt(up3, "Extent", 1, "smallest"); %tiebreaker on image 10

  down = bwpropfilt(bwfill, "Perimeter", [56,600]);
  down2 = bwpropfilt(down, "Eccentricity", [0.865,0.975]);
  down3 = bwpropfilt(down2, "Orientation", [-5, 25]);
  down4 = bwpropfilt(down3, "Extent", [0.25, 0.5]);
  downFinal = bwpropfilt(down4, "Extent", 1, "smallest"); %tiebreaker on image 3

  swan = or(upFinal, downFinal);
  figure;
  imshow(swan);
  title('Combined swan regions');

  % --- Performance Evaluation ---

  % Load ground truth data
  GT = imread(fullfile("GT",file.name));
  figure;
  imshow(GT);
  title('Load ground truth image');

  % Resize ground truth for to match existing data
  GTresize = imresize(GT, 0.5, "bilinear");
  figure;
  imshow(GTresize);
  title('Resizing the ground truth using bilinear interpolation');

  % Binarise ground truth
  GTbw = im2bw(GTresize, 0.5);
  figure;
  imshow(GTbw);
  title('Producing binarised ground truth');

  % Calculate dice score
  similarity = dice(swan, GTbw);
  results(end+1) = similarity;
  pause(2) %prevented crash while testing
  %return %for testing on single image

end

% Return output
results(end+1) = mean(results);
results(end+1) = std(results(1:end-1)); %so doesn't include mean
out = array2table(results.', "RowNames",["Image 1";"Image 2";"Image 3";"Image 4";"Image 5";"Image 6";"Image 7";"Image 8";"Image 9";"Image 10";"Image 11";"Image 12";"Image 13";"Image 14";"Image 15";"Image 16";"Mean";"Standard Deviation"]);
disp(out);


