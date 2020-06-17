#include "stdafx.h"

#include "canvas.h"

#include "lauxlib.h"
#include "lualib.h"


#pragma comment(lib,"lua-5.3.5.lib")

Canvas::Canvas(void) : ls(nullptr), dc_store(0), reporter_fun(nullptr) {
	struct a_bk_line_u {
		BYTE pix[2];
		a_bk_line_u(void) : pix{ 0,0xFF } {}
	};
	struct a_bk_line_d {
		BYTE pix[2];
		a_bk_line_d(void) : pix{ 0xFF,0 } {}
	};
	static const struct {
		a_bk_line_u u[8];
		a_bk_line_d d[8];
	}alpha_bk_pix;
	alpha_bmp.CreateBitmap(16, 16, 1, 1, &alpha_bk_pix);
	alpha_brush.CreatePatternBrush(&alpha_bmp);
}
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
	color_text = 0;

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
		mdc.SetTextColor(color_text);
		CRect rect{ 0,0,size.cx,size.cy };
		mdc.FillSolidRect(&rect, color_brush);
		open_lib_gdi();

		cursor_pos = { 0 };
		res = 0;
	} while (false);

	lua_pop(ls, 1);


	return res;
}

void Canvas::set_cursor(const POINT& p, const RECT& rect) {
	long x = p.x;
	long y = p.y;

	if (stretch) {
		x = (long)(x / (double)(rect.right - rect.left) * size.cx);
		y = (long)(y / (double)(rect.bottom - rect.top) * size.cy);
	}
	else {
		x -= (rect.right - rect.left - size.cx) / 2;
		y -= (rect.bottom - rect.top - size.cy) / 2;
	}

	if (world_axis) {
		x -= size.cx / 2;
		y = size.cy / 2 - y;
	}

	cursor_pos = { x,y };
}

bool Canvas::run(const std::string& name, int state) {
	if (!operator bool())
		return false;
	

	lua_pushvalue(ls, -1);
	//lua_createtable(ls, 0, 1);
	lua_pushstring(ls, name.c_str());


	if (name == "mouse" || name == "scroll")
		lua_pushinteger(ls, state);
	else
		lua_pushboolean(ls, state);

	mdc.SaveDC();

	int res = lua_pcall(ls, 2, 1, 0);

	mdc.RestoreDC(-1);

	report(res);
	
	int redraw = lua_toboolean(ls, -1);
	lua_pop(ls, 1);

	return redraw ? true : false;

}


bool Canvas::draw(CDC* dc,CRect& rect) {
	if (!operator bool())
		return false;

	static const POINT points[] = { {0,300},{300,0},{300,600} };

	if (stretch)
		dc->StretchBlt(rect.left, rect.top, rect.Width(), rect.Height(), &mdc, 0, 0, size.cx, size.cy, SRCCOPY);
	else {
		int state = dc->SaveDC();
		dc->SetTextColor(RGB(192, 192, 192));
		dc->SetBkColor(RGB(128, 128, 128));
		LONG bx = rect.left + (rect.Width() - size.cx) / 2;
		LONG by = rect.top + (rect.Height() - size.cy) / 2;
		dc->BitBlt(bx, by, size.cx, size.cy, &mdc, 0, 0, SRCCOPY);
		if (size.cx < rect.Width()) {
			dc->FillRect(CRect{ rect.left,rect.top,bx,rect.bottom }, &alpha_brush);
			dc->FillRect(CRect{ bx + size.cx,rect.top,rect.right,rect.bottom }, &alpha_brush);
		}
		if (size.cy < rect.Height()){
			dc->FillRect(CRect{ rect.left,rect.top,rect.right,by }, &alpha_brush);
			dc->FillRect(CRect{ rect.left,by + size.cy,rect.right,rect.bottom }, &alpha_brush);
		}
		dc->RestoreDC(state);
	}
	return true;
}

void Canvas::clear(void) {
	if (operator bool())
		mdc.FillSolidRect(0, 0, size.cx, size.cy, RGB(255, 255, 255));
	//index = 0;
	interval = 0;
	cursor_pos = { 0 };

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


#define LIB_MEMBER(F) {#F,Canvas:: F}


void Canvas::open_lib_gdi(void) {
	int type = lua_getglobal(ls, "gdi");
	lua_pop(ls, 1);
	if (type == LUA_TTABLE)
		return;


	static const luaL_Reg members[] = {
		LIB_MEMBER(get),
		LIB_MEMBER(brush),
		LIB_MEMBER(pen),
		LIB_MEMBER(font),
		LIB_MEMBER(msgbox),
		LIB_MEMBER(timer),
		LIB_MEMBER(cursor),
		LIB_MEMBER(fill),
		LIB_MEMBER(line),
		LIB_MEMBER(rectangle),
		LIB_MEMBER(ellipse),
		LIB_MEMBER(pixel),
		LIB_MEMBER(text),
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

	int got = 0;

	luaL_checktype(ls, id, LUA_TTABLE);

	lua_pushnil(ls);
	while (lua_next(ls, id)) {
		switch (lua_type(ls, -2)) {
		case LUA_TNUMBER:
		{
			int i = luaL_checkinteger(ls, -2);
			long v = (long)luaL_checknumber(ls, -1);
			switch (i) {
			case 1:
				res.x = v;
				got |= 1;
				break;
			case 2:
				res.y = v;
				got |= 2;
				break;
			}
			break;
		}
		case LUA_TSTRING:
		{
			const char* s = luaL_checkstring(ls, -2);
			long v = (long)luaL_checknumber(ls, -1);

			if (*s && 0 == *(s + 1)) {
				switch (toupper(*s)) {
				case 'X':
					res.x = v;
					got |= 1;
					break;
				case 'Y':
					res.y = v;
					got |= 2;
					break;
				}
			}
			break;
		}
		}

		lua_pop(ls,1);
	}

	if (got != 3)
		luaL_argerror(ls, id, "Too few arguments in Point");
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


Canvas::DC_state::DC_state(CDC* pdc, lua_State* ls, int index) : dc(pdc), dc_store(0) {
	index = lua_absindex(ls, index);
	if (!lua_istable(ls, index))
		return;

	static const char* properties[] = { "pen","brush","font",nullptr };

	lua_pushnil(ls);
	while (lua_next(ls, index)) {
		switch (luaL_checkoption(ls, -2, NULL, properties)) {
		case 0:	//pen
			set();
			dc->SetDCPenColor(to_color(ls, -1));
			break;
		case 1:	//brush
			set();
			dc->SetDCBrushColor(to_color(ls, -1));
			break;
		case 2:	//font
			set();
			dc->SetTextColor(to_color(ls, -1));
		}
		lua_pop(ls, 1);
	}

}

void Canvas::DC_state::set(void) {
	if (!dc_store)
		dc_store = dc->SaveDC();
}

Canvas::DC_state::~DC_state(void) {
		if (dc && dc_store)
			dc->RestoreDC(dc_store);
	}





void Canvas::parse_config(void) {
//LAPI(parse_config){
	//GET_THIS;
	lua_pushnil(ls);
	while (lua_next(ls, -2)) {
		int pos = lua_gettop(ls);
		lua_pushlightuserdata(ls, this);
		lua_pushcclosure(ls, lfun_config, 1);
		lua_pushvalue(ls, pos - 1);
		lua_pushvalue(ls, pos);
		int res = lua_pcall(ls, 2, 0, 0);
		lua_pop(ls, res == LUA_OK ? 1 : 2);
	}
}

#define LAPI(F) int Canvas:: F(lua_State* ls)
#define GET_THIS Canvas* This = (Canvas*)lua_touserdata(ls,lua_upvalueindex(1))


LAPI(lfun_config) {
	GET_THIS;
	static const char* config[] = { "size","stretch","axis","pen","brush","font",nullptr };
	static const char* axis_config[] = { "screen","world",nullptr };

	switch (luaL_checkoption(ls, -2, NULL, config)) {
	case 0:	//size
	{
		POINT p;
		to_point(p, ls, -1);
		if (p.x > 0 && p.y > 0)
			This->size = { p.x, p.y };
		break;
	}
	case 1:	//stretch
		luaL_checktype(ls, -1, LUA_TBOOLEAN);
		This->stretch = lua_toboolean(ls, -1) ? true : false;
		break;
	case 2:	//axis

		switch (luaL_checkoption(ls, -1, NULL, axis_config)) {
		case 0:	//screen
			This->world_axis = false;
			break;
		case 1:	//world
			This->world_axis = true;
			break;
		}
		break;
	case 3:	//pen
		This->color_pen = to_color(ls, -1);
		break;
	case 4:	//brush
		This->color_brush = to_color(ls, -1);
		break;
	case 5:	//font
		This->color_text = to_color(ls, -1);
		break;
	}
	return 0;
}




LAPI(get) {
	GET_THIS;
	std::string str = luaL_checkstring(ls, 1);
	if (str == "size") {
		lua_pushinteger(ls, This->size.cx);
		lua_pushinteger(ls, This->size.cy);
		return 2;
	}
	if (str == "axis") {
		lua_pushstring(ls, This->world_axis ? "world" : "screen");
		return 1;
	}
	return 0;
}

LAPI(brush) {
	GET_THIS;
	COLORREF old = This->color_brush;
	if (lua_gettop(ls) >= 1) {
		This->color_brush = to_color(ls, 1);
		This->mdc.SetDCBrushColor(This->color_brush);
	}
	lua_pushinteger(ls, old);
	return 1;
}

LAPI(pen) {
	GET_THIS;
	COLORREF old = This->color_pen;
	if (lua_gettop(ls) >= 1) {
		This->color_pen = to_color(ls, 1);
		This->mdc.SetDCPenColor(This->color_pen);
	}
	lua_pushinteger(ls, old);
	return 1;
}

LAPI(font) {
	GET_THIS;
	COLORREF old = This->color_text;
	if (lua_gettop(ls) >= 1) {
		This->color_text = to_color(ls, 1);
		This->mdc.SetTextColor(This->color_text);
	}
	lua_pushinteger(ls, old);
	return 1;
}

LAPI(msgbox) {
	GET_THIS;
	CA2T str(luaL_checkstring(ls, 1));
	MessageBox(NULL, str, _TEXT("LuaCanvas"), MB_OK);
	return 0;
}

LAPI(timer) {
	GET_THIS;
	auto old_interval = This->interval;
	auto v = luaL_optinteger(ls, -1,old_interval);
	This->interval = max(0, v);
	lua_pushinteger(ls, old_interval);
	return 1;
}

LAPI(cursor) {
	GET_THIS;
	lua_pushinteger(ls, This->cursor_pos.x);
	lua_pushinteger(ls, This->cursor_pos.y);
	return 2;
}

LAPI(fill) {
	GET_THIS;

	CRect rect;
	COLORREF color = This->color_brush;

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

	DC_state state(&This->mdc, ls, 3);
	

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

	DC_state state(&This->mdc, ls, 3);

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

	DC_state state(&This->mdc, ls, 3);

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

LAPI(text) {
	GET_THIS;
	size_t len = 0;
	POINT p;
	to_point(p, ls, 1);
	This->translate_point(p);

	CA2T str(luaL_checklstring(ls, 2, &len));

	DC_state state(&This->mdc, ls, 3);

	This->mdc.TextOut(p.x, p.y, (LPCTSTR)str);

	CSize text_extent = This->mdc.GetTextExtent(str, len);
	lua_pushinteger(ls, text_extent.cx);
	lua_pushinteger(ls, text_extent.cy);

	return 2;
}

#undef LAPI