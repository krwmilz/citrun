/*
 * Copyright 2012 Google, Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Google Author(s): Behdad Esfahbod, Maysum Panju
 */

#ifndef DEMO_COMMON_H
#define DEMO_COMMON_H

#include "glyphy/glyphy.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>

#include <algorithm>
#include <vector>

#include <GL/glew.h>
#include <GLES2/gl2.h>

#if defined(__APPLE__)
#  include <OpenGL/OpenGL.h>
#  include <GLUT/glut.h>
#else
#  include <GL/glut.h>
#endif


#define ARRAY_LEN(Array) (sizeof (Array) / sizeof (*Array))

#define MIN_FONT_SIZE 10
#define TOLERANCE (1./2048)

#define LOGI(...) ((void) fprintf (stdout, __VA_ARGS__))
#define LOGW(...) ((void) fprintf (stderr, __VA_ARGS__))
#define LOGE(...) ((void) fprintf (stderr, __VA_ARGS__), abort ())

static inline void
die (const char *msg)
{
	fprintf (stderr, "%s\n", msg);
	exit (1);
}

template <typename T>
T clamp (T v, T m, T M)
{
  return v < m ? m : v > M ? M : v;
}

struct auto_trace_t
{
  auto_trace_t (const char *func_) : func (func_)
  { printf ("Enter: %s\n", func); }

  ~auto_trace_t (void)
  { printf ("Leave: %s\n", func); }

  private:
  const char * const func;
};

#define TRACE() auto_trace_t trace(__func__)

#endif /* DEMO_COMMON_H */
