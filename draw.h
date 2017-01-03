#ifndef DRAW_H
#define DRAW_H

class drawable {
public:
	virtual void draw() = 0;
	virtual void idle() = 0;
};

#endif
