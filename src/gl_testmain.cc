//
// osdemo.c originally from Brian Paul, public domain.
// PPM output provided by Joerg Schmalzl.
// ASCII PPM output added by Brian Paul.
//
#include <err.h>
#include <GL/glew.h>
#define GLAPI extern
#include <GL/osmesa.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "gl_buffer.h"
#include "gl_font.h"
#include "gl_procfile.h"
#include "gl_view.h"
#include "process_dir.h"


#define SAVE_TARGA

static int Width = 400;
static int Height = 400;


static void
render_image(void)
{
	ProcessDir m_pdir;
	std::vector<GlProcessFile> drawables;

	demo_glstate_t *st = demo_glstate_create();
	GlBuffer text_buffer;

	View *static_vu = new View(st);

	demo_font_t *font = demo_font_create(demo_glstate_get_atlas(st));

	static_vu->setup();

	glyphy_point_t top_left = { 0, 0 };
	text_buffer.move_to(&top_left);
	text_buffer.add_text("waiting...", font, 1);

	for (std::string &file_name : m_pdir.scan())
		drawables.emplace_back(file_name, font);

	glyphy_extents_t extents;
	for (auto &i : drawables) {
		glyphy_extents_t t = i.get_extents();
		extents.max_x = std::max(extents.max_x, t.max_x);
		extents.max_y = std::max(extents.max_y, t.max_y);
		extents.min_x = std::min(extents.min_x, t.min_x);
		extents.min_y = std::min(extents.min_y, t.min_y);
	}

	// Set up view transforms
	static_vu->display(extents);

	text_buffer.draw();

	for (auto &i : drawables)
		i.display();
}

#ifdef SAVE_TARGA
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
      fputc (Width & 0xff, f);      /* Image Width	*/
      fputc ((Width>>8) & 0xff, f);
      fputc (Height & 0xff, f);     /* Image Height	*/
      fputc ((Height>>8) & 0xff, f);
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
#else
static void
write_ppm(const char *filename, const GLubyte *buffer, int width, int height)
{
   const int binary = 0;
   FILE *f = fopen( filename, "w" );
   if (f) {
      int i, x, y;
      const GLubyte *ptr = buffer;
      if (binary) {
         fprintf(f,"P6\n");
         fprintf(f,"# ppm-file created by osdemo.c\n");
         fprintf(f,"%i %i\n", width,height);
         fprintf(f,"255\n");
         fclose(f);
         f = fopen( filename, "ab" );  /* reopen in binary append mode */
         for (y=height-1; y>=0; y--) {
            for (x=0; x<width; x++) {
               i = (y*width + x) * 4;
               fputc(ptr[i], f);   /* write red */
               fputc(ptr[i+1], f); /* write green */
               fputc(ptr[i+2], f); /* write blue */
            }
         }
      }
      else {
         /*ASCII*/
         int counter = 0;
         fprintf(f,"P3\n");
         fprintf(f,"# ascii ppm file created by osdemo.c\n");
         fprintf(f,"%i %i\n", width, height);
         fprintf(f,"255\n");
         for (y=height-1; y>=0; y--) {
            for (x=0; x<width; x++) {
               i = (y*width + x) * 4;
               fprintf(f, " %3d %3d %3d", ptr[i], ptr[i+1], ptr[i+2]);
               counter++;
               if (counter % 5 == 0)
                  fprintf(f, "\n");
            }
         }
      }
      fclose(f);
   }
}
#endif // SAVE_TARGA

int
main(int argc, char *argv[])
{
	OSMesaContext	 ctx;
	void		*buffer;
	char		*filename = NULL;

	if (argc < 2) {
		fprintf(stderr, "Usage:\n");
		fprintf(stderr, "  %s filename [width height]\n", argv[0]);
		return 0;
	}

	filename = argv[1];
	if (argc == 4) {
		Width = atoi(argv[2]);
		Height = atoi(argv[3]);
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
	if ((buffer = malloc(Width * Height * 4 * sizeof(GLubyte))) == NULL)
		errx(1, "Alloc image buffer failed!");

	// Bind the buffer to the context and make it current
	if (!OSMesaMakeCurrent(ctx, buffer, GL_UNSIGNED_BYTE, Width, Height))
		errx(1, "OSMesaMakeCurrent failed!");

	int z, s, a;
	glGetIntegerv(GL_DEPTH_BITS, &z);
	glGetIntegerv(GL_STENCIL_BITS, &s);
	glGetIntegerv(GL_ACCUM_RED_BITS, &a);
	printf("Depth=%d Stencil=%d Accum=%d\n", z, s, a);

	GLenum glew_status = glewInit();
	if (GLEW_OK != glew_status)
		errx(1, "%s", glewGetErrorString(glew_status));
	if (!glewIsSupported("GL_VERSION_2_0"))
		errx(1, "No support for OpenGL 2.0 found");

	render_image();

	if (filename != NULL)
#ifdef SAVE_TARGA
		write_targa(filename, static_cast<const GLubyte *>(buffer), Width, Height);
#else
		write_ppm(filename, static_cast<const GLubyte *>(buffer), Width, Height);
#endif
	else
		printf("Specify a filename if you want to make an image file\n");

	printf("all done\n");

	free(buffer);
	OSMesaDestroyContext( ctx );

	return 0;
}
