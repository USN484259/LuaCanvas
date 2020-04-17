#include "stdafx.h"

#include "canvas.h"

#include "lauxlib.h"
#include "lualib.h"

#pragma comment(lib,"lua-5.3.5.lib")

Canvas::Canvas(void) : ls(nullptr), dc_store(0), reporter_fun(nullptr) {}
Canvas::~Canvas(void) {
	reset();
}

void Canvas::reset(void) {
	if (ls) {
		lua_close(ls);
		ls = nullptr;
	}
	if (dc_store) {
		mdc.RestoreDC(dc_store);
		mdc.DeleteDC();
		//brush.DeleteObject();
		//pen.DeleteObject();
		bmp.DeleteObject();
		dc_store = 0;
	}
}

Canvas::operator bool(void) const {
	return ls && dc_store && lua_isfunction(ls, -1);
}

bool Canvas::load(const char* filename,CDC* dc,CRect& rect) {
		reset();
		ls = luaL_newstate();
		if (!ls) {
			report("Failed luaL_newstate");
			return false;
		}
		luaL_openlibs(ls);

		int res = luaL_loadfilex(ls, filename, NULL);
		report(res);
		if (res)
			return false;
		return init(dc,rect) ? false : true;
}



int Canvas::init(CDC* dc,CRect& rect) {
	int res = lua_pcall(ls, 0, 2, 0);
	report(res);
	if (res) {
		return res;
	}
	res = -1;

	//default config
	size = { rect.Width(),rect.Height() };
	interval = 0;
	stretch = false;
	world_axis = false;
	color_pen = 0;
	color_brush = 0x00FFFFFF;

	if (lua_istable(ls, -1)) {
		parse_config();
	}


	do {
		if (!mdc.CreateCompatibleDC(dc)) {
			report("Failed CreateCompatibleDC");
			break;
		}
		if (!bmp.CreateCompatibleBitmap(dc, size.cx, size.cy)) {
			report("Failed CreateCompatibleBitmap");
			break;
		}



		dc_store = mdc.SaveDC();
		mdc.SetBkMode(TRANSPARENT);
		mdc.SetBkColor(RGB(255, 255, 255));
		mdc.SelectObject(bmp);
		mdc.SelectObject(GetStockObject(DC_PEN));
		mdc.SelectObject(GetStockObject(DC_BRUSH));
		mdc.SetDCPenColor(color_pen);
		mdc.SetDCBrushColor(color_brush);

		open_lib_gdi();
		index = 0;
		res = 0;
	} while (false);

	lua_pop(ls, 1);
	return res;
}


bool Canvas::run(void) {
	if (!operator bool())
		return false;
	mdc.SaveDC();


	lua_pushvalue(ls, -1);
	lua_pushinteger(ls, index);
	int res = lua_pcall(ls, 1, 1, 0);

	mdc.RestoreDC(-1);

	report(res);

	index = lua_tointeger(ls, -1);	//returns 0 if not integer
	lua_pop(ls, 1);
	return index ? true : false;

}


bool Canvas::draw(CDC* dc,CRect& rect) {
	if (!operator bool())
		return false;


	if (stretch)
		dc->StretchBlt(rect.left, rect.top, rect.Width(), rect.Height(), &mdc, 0, 0, size.cx, size.cy, SRCCOPY);
	else {
		LONG bx = rect.left + (rect.Width() - size.cx) / 2;
		LONG by = rect.top + (rect.Height() - size.cy) / 2;
		dc->BitBlt(bx, by, size.cx, size.cy, &mdc, 0, 0, SRCCOPY);
		if (size.cx < rect.Width()) {
			dc->FillSolidRect(CRect{ rect.left,rect.top,bx,rect.bottom }, RGB(255, 255, 255));
			dc->FillSolidRect(CRect{ bx + size.cx,rect.top,rect.right,rect.bottom }, RGB(255, 255, 255));
		}
		if (size.cy < rect.Height()){
			dc->FillSolidRect(CRect{ rect.left,rect.top,rect.right,by }, RGB(255, 255, 255));
			dc->FillSolidRect(CRect{ rect.left,by + size.cy,rect.right,rect.bottom }, RGB(255, 255, 255));
		}
	}
	return true;
}

void Canvas::clear(void) {
	if (operator bool())
		mdc.FillSolidRect(0, 0, size.cx, size.cy, RGB(255, 255, 255));
	index = 0;
}
size_t Canvas::get_interval(void) const {
	return interval;
}

void Canvas::reporter(reporter_type r, void* a) {
	reporter_fun = r;
	reporter_arg = a;
}

void Canvas::report(const char* msg) {
	if (reporter_fun) {
		reporter_fun(msg, reporter_arg);
	}
}

void Canvas::report(int state) {
	if (state && reporter_fun)
		;
	else
		return;
	LUA_ERRFILE;
	static const char* errmsg[] = { "Unknown error","Yield","Runtime error","Syntax error","Bad alloc","Bad GC","Nested error","Cannot open file" };
	static_assert(_countof(errmsg) == 1 + LUA_ERRFILE,"lua errmsg mismatch");

	CStringA msg((state > 0 && state <= LUA_ERRFILE) ? errmsg[state] : errmsg[0]);
	while (lua_gettop(ls) && lua_isstring(ls, -1)) {
		msg.Append(" ");
		msg.Append(lua_tostring(ls, -1));
		lua_pop(ls, 1);
	}
	reporter_fun(msg, reporter_arg);
}

//#define LIB_MEMBER(F) lua_pushstring(ls,#F), lua_pushlightuserdata(ls,this), lua_pushcclosure(ls,Canvas:: F, 1), lua_settable(ls,-3)

#define LIB_MEMBER(F) {#F,Canvas:: F}


void Canvas::open_lib_gdi(void) {
	int type = lua_getglobal(ls, "gdi");
	lua_pop(ls, 1);
	if (type == LUA_TTABLE)
		return;


	static const luaL_Reg members[] = {
		LIB_MEMBER(area),
		LIB_MEMBER(fill),
		LIB_MEMBER(line),
		LIB_MEMBER(rectangle),
		LIB_MEMBER(ellipse),
		LIB_MEMBER(pixel),
		{ 0 }
	};

	luaL_newlibtable(ls, members);
	lua_pushlightuserdata(ls, this);
	luaL_setfuncs(ls, members, 1);

	lua_setglobal(ls, "gdi");
}

#undef LIB_MEMBER

void Canvas::to_point(POINT& res,lua_State* ls,int id) {
	id = lua_absindex(ls, id);

	luaL_checktype(ls, id, LUA_TTABLE);
	lua_pushinteger(ls, 1);
	lua_gettable(ls, id);
	res.x = luaL_checkinteger(ls, -1);
	lua_pushinteger(ls, 2);
	lua_gettable(ls, id);
	res.y = luaL_checkinteger(ls, -1);
	lua_pop(ls, 2);
}

void Canvas::get_rect(RECT& rect,const POINT& a,const POINT& b) {
	if (a.x < b.x) {
		rect.left = a.x;
		rect.right = b.x;
	}
	else {
		rect.left = b.x;
		rect.right = a.x;
	}
	if (a.y < b.y) {
		rect.top = a.y;
		rect.bottom = b.y;
	}
	else {
		rect.top = b.y;
		rect.bottom = a.y;
	}
}

COLORREF Canvas::to_color(lua_State* ls,int id) {
	id = lua_absindex(ls, id);
	if (lua_isinteger(ls, id))
		return lua_tointeger(ls, id) & 0x00FFFFFF;

	luaL_checktype(ls, id, LUA_TTABLE);
	COLORREF color = 0;
	for (auto i = 3; i >= 1; --i) {
		color <<= 8;
		lua_pushinteger(ls, i);
		lua_gettable(ls, id);
		color |= (0xFF & luaL_checkinteger(ls, -1));
	}
	lua_pop(ls, 3);
	return color;
}

void Canvas::translate_point(POINT& p) {
	if (world_axis) {
		p.x += size.cx / 2;
		p.y = size.cy / 2 - p.y;
	}
}

class DC_state {
	CDC* dc;
	int dc_store;


public:
	DC_state(CDC* pdc,lua_State* ls,int index) : dc(nullptr), dc_store(0) {
		index = lua_absindex(ls,index);
		if (!lua_istable(ls, index))
			return;

		static const char* properties[] = { "pen","brush",nullptr };

		lua_pushnil(ls);
		while (lua_next(ls, index)) {
			switch (luaL_checkoption(ls, -2, NULL, properties)) {
			case 0:	//pen
				break;
			case 1:	//brush
				break;
			}
		}



	}
	~DC_state(void) {
		if (dc && dc_store)
			dc->RestoreDC(dc_store);
	}
};


#define LAPI(F) int Canvas:: F(lua_State* ls)
#define GET_THIS Canvas* This = (Canvas*)lua_touserdata(ls,lua_upvalueindex(1))


void Canvas::parse_config(void) {
	lua_pushnil(ls);
	while (lua_next(ls, -2)) {

		static const char* config[] = { "size","stretch","axis","anime","pen","brush",nullptr };
		static const char* axis_config[] = { "screen","world",nullptr };

		switch (luaL_checkoption(ls, -2, NULL, config)) {
		case 0:	//size
		{
			POINT p;
			to_point(p, ls, -1);
			if (p.x > 0 && p.y > 0)
				size = { p.x, p.y };
			break;
		}
		case 1:	//stretch
			luaL_checktype(ls, -1, LUA_TBOOLEAN);
			stretch = lua_toboolean(ls, -1) ? true : false;
			break;
		case 2:	//axis
			switch (luaL_checkoption(ls, -1, NULL, axis_config)) {
			case 0:	//screen
				world_axis = false;
				break;
			case 1:	//world
				world_axis = true;
				break;
			}
			break;
		case 3:	//anime
			interval = luaL_checkinteger(ls, -1);
			break;
		case 4:	//pen
			color_pen = to_color(ls,-1);
			break;
		case 5:	//brush
			color_brush = to_color(ls,-1);
			break;
		}

		lua_pop(ls, 1);
	}


}



LAPI(area) {
	GET_THIS;
	
	lua_pushinteger(ls, This->size.cx);
	lua_pushinteger(ls, This->size.cy);
	return 2;
}

LAPI(fill) {
	GET_THIS;

	CRect rect;
	DWORD color = This->color_brush;

	if (lua_gettop(ls) > 1) {
		rect = { (int)luaL_checkinteger(ls, 1), (int)luaL_checkinteger(ls, 2), (int)luaL_checkinteger(ls, 3), (int)luaL_checkinteger(ls, 4) };
		if (!lua_isnoneornil(ls,5))
			color = to_color(ls, 5);
	}
	else {
		rect = { 0,0,This->size.cx,This->size.cy };
		if (!lua_isnoneornil(ls, 1))
			color = to_color(ls, 1);
	}
	This->mdc.FillSolidRect(&rect, color);

	return 0;
}

LAPI(line) {
	GET_THIS;
	POINT from, to;
	to_point(from, ls, 1);
	to_point(to, ls, 2);

	This->translate_point(from);
	This->translate_point(to);
	//TODO
	//DC_state state(&This->mdc, pid);
	

	This->mdc.MoveTo(from);
	This->mdc.LineTo(to);

	return 0;
}


LAPI(rectangle) {
	GET_THIS;
	POINT from, to;
	to_point(from, ls, 1);
	to_point(to, ls, 2);

	This->translate_point(from);
	This->translate_point(to);

	RECT rect;
	get_rect(rect, from, to);
	//TODO
	//DC_state state(&This->mdc, pid);

	This->mdc.Rectangle(&rect);

	return 0;
}

LAPI(ellipse) {
	GET_THIS;
	POINT from, to;
	to_point(from, ls, 1);
	to_point(to, ls, 2);

	This->translate_point(from);
	This->translate_point(to);

	RECT rect;
	get_rect(rect, from, to);
	//TODO
	//DC_state state(&This->mdc, pid);

	This->mdc.Ellipse(&rect);

	return 0;
}

LAPI(pixel) {
	GET_THIS;
	POINT p;
	to_point(p, ls, 1);
	This->translate_point(p);

	COLORREF color = to_color(ls, 2);

	This->mdc.SetPixelV(p.x, p.y, color);
	return 0;
}

#undef LAPI