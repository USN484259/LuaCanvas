#pragma once
#include "stdafx.h"
#include "lua.h"
#include <string>

class Canvas {
public:
	typedef void(*reporter_type)(const char*, void*);
private:
	lua_State* ls;
	CDC mdc;
	CBitmap bmp;
	SIZE size;
	CBitmap alpha_bmp;
	CBrush alpha_brush;
	int dc_store;

	DWORD interval;

	bool world_axis;
	bool stretch;

	COLORREF color_pen;
	COLORREF color_brush;
	COLORREF color_text;

	reporter_type reporter_fun;
	void* reporter_arg;
	POINT cursor_pos;

private:
	class DC_state {
		CDC* dc;
		int dc_store;

		void set(void);

	public:
		DC_state(CDC*, lua_State*, int);
		~DC_state(void);
	};

private:
	int init(CDC*,CRect&);
	void parse_config(void);
	void open_lib_gdi(void);
	static void to_point(POINT&,lua_State*, int);
	static void get_rect(RECT&,const POINT&,const POINT&);
	static COLORREF to_color(lua_State*,int);

	void translate_point(POINT&);

#define LAPI(F) static int F(lua_State*)
	LAPI(lfun_config);

	LAPI(get);
	LAPI(brush);
	LAPI(pen);
	LAPI(font);
	LAPI(msgbox);
	LAPI(timer);
	LAPI(cursor);
	LAPI(fill);
	LAPI(line);
	LAPI(rectangle);
	LAPI(ellipse);
	LAPI(pixel);
	LAPI(text);

#undef LAPI
public:

	Canvas(void);
	~Canvas(void);
	void reset(void);
	bool load(const char*,CDC*,CRect&);
	bool run(const std::string&,int);
	void set_cursor(const POINT&, const RECT&);
	bool draw(CDC*,CRect&);
	void clear(void);

	size_t get_interval(void) const;
	operator bool(void) const;
	void reporter(reporter_type, void*);
	void report(const char*);
	void report(int);
};