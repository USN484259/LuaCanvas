#pragma once
#include "stdafx.h"
#include "lua.h"

class Canvas {
public:
	typedef void(*reporter_type)(const char*, void*);
private:
	lua_State* ls;
	CDC mdc;
	CBitmap bmp;
	SIZE size;
	int dc_store;
	size_t index;

	DWORD interval;
	bool world_axis;
	bool stretch;
	COLORREF color_pen;
	COLORREF color_brush;

	reporter_type reporter_fun;
	void* reporter_arg;


private:
	int init(CDC*,CRect&);
	void parse_config(void);
	void open_lib_gdi(void);
	static void to_point(POINT&,lua_State*, int);
	static void get_rect(RECT&,const POINT&,const POINT&);
	static COLORREF to_color(lua_State*,int);

	void translate_point(POINT&);

#define LAPI(F) static int F(lua_State*)

	//static int open_lib_gdi(lua_State*);
	//static int line(lua_State*);
	LAPI(area);
	LAPI(fill);
	LAPI(line);
	LAPI(rectangle);
	LAPI(ellipse);
	LAPI(pixel);

#undef LAPI
public:

	Canvas(void);
	~Canvas(void);
	void reset(void);
	bool load(const char*,CDC*,CRect&);
	bool run(void);
	bool draw(CDC*,CRect&);
	void clear(void);

	size_t get_interval(void) const;
	operator bool(void) const;
	void reporter(reporter_type, void*);
	void report(const char*);
	void report(int);
};