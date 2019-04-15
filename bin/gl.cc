#include <GL/glew.h>		// glewInit, glewIsSupported
#include <GLFW/glfw3.h>
#define GLAPI extern
#include <GL/osmesa.h>		// OSMesa{Context,CreateContext,MakeCurrent}

#include <err.h>
#include <stdio.h>		// fclose, fopen, fputc
#include <stdlib.h>
#include <string.h>

#include "gl_main.h"		// citrun::gl_main


void
keyboard_func(GLFWwindow *window, int key, int scancode, int action, int mods)
{
	//static_vu->keyboard_func(window, key, scancode, action, mods);
}

static void
error_callback(int error, const char *desc)
{
	fprintf(stderr, "Error: %s\n", desc);
}

//
// osdemo.c originally from Brian Paul, public domain.
//
static void
write_targa(const char *filename, const GLubyte *buffer, int width, int height)
{
   FILE *f = fopen( filename, "w" );
   if (f) {
      int i, x, y;
      const GLubyte *ptr = buffer;
      printf ("osdemo, writing tga file \n");
      fputc (0x00, f);	/* ID Length, 0 => No ID	*/
      fputc (0x00, f);	/* Color Map Type, 0 => No color map included	*/
      fputc (0x02, f);	/* Image Type, 2 => Uncompressed, True-color Image */
      fputc (0x00, f);	/* Next five bytes are about the color map entries */
      fputc (0x00, f);	/* 2 bytes Index, 2 bytes length, 1 byte size */
      fputc (0x00, f);
      fputc (0x00, f);
      fputc (0x00, f);
      fputc (0x00, f);	/* X-origin of Image	*/
      fputc (0x00, f);
      fputc (0x00, f);	/* Y-origin of Image	*/
      fputc (0x00, f);
      fputc (width & 0xff, f);      /* Image Width	*/
      fputc ((width>>8) & 0xff, f);
      fputc (height & 0xff, f);     /* Image Height	*/
      fputc ((height>>8) & 0xff, f);
      fputc (0x18, f);		/* Pixel Depth, 0x18 => 24 Bits	*/
      fputc (0x20, f);		/* Image Descriptor	*/
      fclose(f);
      f = fopen( filename, "ab" );  /* reopen in binary append mode */
      for (y=height-1; y>=0; y--) {
         for (x=0; x<width; x++) {
            i = (y*width + x) * 4;
            fputc(ptr[i+2], f); /* write blue */
            fputc(ptr[i+1], f); /* write green */
            fputc(ptr[i], f);   /* write red */
         }
      }
   }
}

int
altmain(int argc, char *argv[])
{
	OSMesaContext	 ctx;
	void		*buffer;
	char		*filename = NULL;
	int		 width = 400;
	int		 height = 400;

	filename = argv[1];
	if (filename == NULL)
		errx(0,"Specify a filename if you want to make an image file");

	if (argc == 4) {
		width = atoi(argv[2]);
		height = atoi(argv[3]);
	}

	// Create an RGBA-mode context
#if OSMESA_MAJOR_VERSION * 100 + OSMESA_MINOR_VERSION >= 305
	// specify Z, stencil, accum sizes
	ctx = OSMesaCreateContextExt(OSMESA_RGBA, 16, 0, 0, NULL);
#else
	ctx = OSMesaCreateContext(OSMESA_RGBA, NULL);
#endif
	if (!ctx)
		errx(1, "OSMesaCreateContext failed!");

	// Allocate the image buffer
	if ((buffer = malloc(width * height * 4 * sizeof(GLubyte))) == NULL)
		errx(1, "Alloc image buffer failed!");

	// Bind the buffer to the context and make it current
	if (!OSMesaMakeCurrent(ctx, buffer, GL_UNSIGNED_BYTE, width, height))
		errx(1, "OSMesaMakeCurrent failed!");

	int z, s, a;
	glGetIntegerv(GL_DEPTH_BITS, &z);
	glGetIntegerv(GL_STENCIL_BITS, &s);
	glGetIntegerv(GL_ACCUM_RED_BITS, &a);
	printf("Depth=%d Stencil=%d Accum=%d\n", z, s, a);

	GLenum glew_status = glewInit();
	if (GLEW_OK != glew_status)
		errx(1, "glewInit %s", glewGetErrorString(glew_status));
	if (!glewIsSupported("GL_VERSION_2_0"))
		errx(1, "No support for OpenGL 2.0 found");

	citrun::gl_main main;
	main.tick();

	write_targa(filename, static_cast<const GLubyte *>(buffer), width, height);
	printf("all done\n");

	free(buffer);
	OSMesaDestroyContext( ctx );

	return 0;
}

int
main(int argc, char *argv[])
{
	if (argc > 1)
		return altmain(argc, argv);

	GLFWwindow *window;

	glfwSetErrorCallback(error_callback);

	if (!glfwInit())
		return 1;

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
	glfwWindowHint(GLFW_SRGB_CAPABLE, 1);

	window = glfwCreateWindow(1600, 1200, "C It Run", NULL, NULL);
	if (window == NULL) {
		glfwTerminate();
		return 1;
	}

	glfwSetKeyCallback(window, keyboard_func);

	glfwMakeContextCurrent(window);
	glfwSwapInterval(1);

	GLenum glew_status = glewInit();
	if (GLEW_OK != glew_status)
		errx(1, "%s", glewGetErrorString(glew_status));
	if (!glewIsSupported("GL_VERSION_2_0"))
		errx(1, "No support for OpenGL 2.0 found");

	citrun::gl_main main;

	while (!glfwWindowShouldClose(window)) {

		main.tick();

		glfwSwapBuffers(window);
		glfwPollEvents();
	}

	glfwDestroyWindow(window);
	glfwTerminate();

	return 0;
}
