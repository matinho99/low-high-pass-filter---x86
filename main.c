#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <CImg.h>

#ifdef __cplusplus
extern "C" {
#endif
 int func(char *in, char *out, char *filterType);
#ifdef __cplusplus
}
#endif

using namespace cimg_library;

int main(int argc, char** argv) {
  if(argc!=4) {
    printf("./result <input_file_name> <output_file_name> <filter_type>\n");
    exit(0);
  }

  if(atoi(argv[3])!=1 && atoi(argv[3])!=2) {
    printf("<filter_type> can be:\n1. Low-Pass\n2. High-Pass\n");
    exit(0);
  }

  FILE* f = fopen(argv[1],"rb");

  if(!f) {
    printf("Input file does not exist\n");
    exit(0);
  }

  FILE* fOut = fopen(argv[2], "wb");
  
  if(!fOut) {
    exit(0);
  }

  int check=0;
  fseek(f, 0, SEEK_END);
  int fileSize=ftell(f);
  fseek(f, 0, SEEK_SET);          
  char* inFileBuff=(char *)malloc(fileSize+1);
  char* outFileBuff=(char *)malloc(fileSize+1);
  memset(inFileBuff, 0, fileSize);
  memset(outFileBuff, 0, fileSize);
  fread(inFileBuff, fileSize, 1, f);
  func(inFileBuff, outFileBuff, argv[3]);
  fwrite(outFileBuff, fileSize, 1, fOut);

  CImg<unsigned char> inImage(argv[1]), outImage(argv[2]);
  inImage.resize_doubleXY();
  outImage.resize_doubleXY();
  CImgDisplay inDisplay(inImage,"In image"), outDisplay(outImage,"Out image");  

  while (!inDisplay.is_closed() && !outDisplay.is_closed()) {
    inDisplay.wait();
    outDisplay.wait();
  }

  fclose(f);
  remove(argv[2]);
  free(inFileBuff);
  free(outFileBuff);
  return 0;
}
