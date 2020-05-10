
// LuaCanvasView.cpp : implementation of the CLuaCanvasView class
//

#include "stdafx.h"
#include "LuaCanvas.h"
#include "LuaCanvasView.h"
#include <cctype>
#include "resource.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif



const std::unordered_map<char, const char*> CLuaCanvasView::key_mapping = {
	{VK_BACK,"backspace"},
	{VK_TAB,"tab"},
	{VK_RETURN,"enter"},
	{VK_SHIFT,"shift"},
	{VK_CONTROL,"ctrl"},
	{VK_ESCAPE,"esc"},
	{VK_SPACE," "},
	{VK_PRIOR,"pageup"},
	{VK_NEXT,"pagedown"},
	{VK_END,"end"},
	{VK_HOME,"home"},
	{VK_LEFT,"left"},
	{VK_RIGHT,"right"},
	{VK_UP,"up"},
	{VK_DOWN,"down"},
	{VK_DELETE,"delete"},
	{VK_OEM_1,";"},
	{VK_OEM_PLUS,"="},
	{VK_OEM_COMMA,","},
	{VK_OEM_MINUS,"-"},
	{VK_OEM_PERIOD,"."},
	{VK_OEM_2,"/"},
	{VK_OEM_3,"`"},
	{VK_OEM_4,"["},
	{VK_OEM_5,"\\"},
	{VK_OEM_6,"]"},
	{VK_OEM_7,"\'"}
};

// CLuaCanvasView

CLuaCanvasView::CLuaCanvasView() : timer(NULL)
{
	canvas.reporter(on_report, this);
}

CLuaCanvasView::~CLuaCanvasView()
{
}


BEGIN_MESSAGE_MAP(CLuaCanvasView, CWnd)
	ON_WM_PAINT()
	ON_COMMAND(ID_CANVAS_CLEAR, &CLuaCanvasView::OnCanvasClear)
	ON_COMMAND(ID_CANVAS_DRAW, &CLuaCanvasView::OnCanvasDraw)
	ON_COMMAND(ID_FILE_CLOSE, &CLuaCanvasView::OnFileClose)
	ON_COMMAND(ID_FILE_OPEN, &CLuaCanvasView::OnFileOpen)
	ON_WM_ERASEBKGND()
	ON_WM_CLOSE()
	ON_WM_TIMER()
//	ON_WM_SIZING()
ON_WM_KEYDOWN()
ON_WM_KEYUP()
END_MESSAGE_MAP()



// CLuaCanvasView message handlers

BOOL CLuaCanvasView::PreCreateWindow(CREATESTRUCT& cs) 
{
	if (!CWnd::PreCreateWindow(cs))
		return FALSE;

	cs.dwExStyle |= WS_EX_CLIENTEDGE;
	cs.style &= ~WS_BORDER;
	cs.lpszClass = AfxRegisterWndClass(CS_HREDRAW|CS_VREDRAW|CS_DBLCLKS, 
		::LoadCursor(NULL, IDC_ARROW), reinterpret_cast<HBRUSH>(COLOR_WINDOW+1), NULL);

	return TRUE;
}

void CLuaCanvasView::timer_stop(void) {
	if (timer) {
		KillTimer(timer);
		timer = NULL;
	}
}

void CLuaCanvasView::timer_start(DWORD interval) {
	if (!interval)
		return;
	timer_stop();
	timer = SetTimer(1, interval, NULL);
}

void CLuaCanvasView::on_report(const char* msg, void* This) {
	CA2T str(msg);
	((CLuaCanvasView*)This)->timer_stop();
	((CLuaCanvasView*)This)->MessageBox(str);
}

void CLuaCanvasView::OnPaint() 
{
	CPaintDC dc(this); // device context for painting
	
	// TODO: Add your message handler code here
	
	// Do not call CWnd::OnPaint() for painting messages
	CRect rect;

	GetClientRect(&rect);

	if (!canvas.draw(&dc, rect))
		dc.FillSolidRect(&rect, RGB(255, 255, 255));
}



void CLuaCanvasView::OnCanvasClear()
{
	timer_stop();
	canvas.clear();
	InvalidateRect(NULL);
	UpdateWindow();

}


void CLuaCanvasView::OnCanvasDraw()
{
	// TODO: 在此添加命令处理程序代码
	bool res = canvas.run();
	InvalidateRect(NULL);
	UpdateWindow();
	if (res)
		timer_start(canvas.get_interval());
}


void CLuaCanvasView::OnFileClose()
{
	timer_stop();
	canvas.reset();
	title(nullptr);
	InvalidateRect(NULL);
	UpdateWindow();
}


void CLuaCanvasView::OnFileOpen()
{
	// TODO: 在此添加命令处理程序代码
	CFileDialog file_picker(TRUE, NULL, NULL, OFN_HIDEREADONLY, _T("Lua files (*.lua)|*.lua|All Files (*.*)|*.*||"));
	if (file_picker.DoModal() == IDOK) {
		CString filename = file_picker.GetPathName();
		if (!filename.IsEmpty()) {
			timer_stop();
			CDC* dc = GetDC();
			CRect rect;
			GetClientRect(&rect);

			CT2A str(filename);
			bool res = canvas.load(str, dc, rect);

			ReleaseDC(dc);

			if (res) {
				title(filename);
				InvalidateRect(NULL);
				UpdateWindow();
			}
		}
	}

}


BOOL CLuaCanvasView::OnEraseBkgnd(CDC* pDC)
{
	// TODO: 在此添加消息处理程序代码和/或调用默认值
	return TRUE;
	//return CWnd::OnEraseBkgnd(pDC);
}


void CLuaCanvasView::OnClose()
{
	// TODO: 在此添加消息处理程序代码和/或调用默认值
	timer_stop();
	CWnd::OnClose();
}


void CLuaCanvasView::OnTimer(UINT_PTR nIDEvent)
{
	// TODO: 在此添加消息处理程序代码和/或调用默认值
	if (nIDEvent == timer) {
		bool res = canvas.run();
		InvalidateRect(NULL);
		UpdateWindow();
		if (!res)
			timer_stop();
	}
	CWnd::OnTimer(nIDEvent);
}

void CLuaCanvasView::title(LPCTSTR str) {
	CString tit(_TEXT("LuaCanvas"));

	if (str) {
		tit.Append(_TEXT(" - "));
		tit.Append(str);
	}
	GetParentFrame()->SetWindowText(tit);
}

//void CLuaCanvasView::OnSizing(UINT fwSide, LPRECT pRect)
//{
//	//CWnd::OnSizing(fwSide, pRect);
//
//}

void CLuaCanvasView::key_translate(std::string& res, char c) {
	using namespace std;
	res.clear();
	if (isupper((byte)c) || isdigit((byte)c)) {
		res.append(1, c);
		return;
	}
	auto it = key_mapping.find(c);
	if (it != key_mapping.cend())
		res.append(it->second);

}

void CLuaCanvasView::OnKeyDown(UINT nChar, UINT nRepCnt, UINT nFlags)
{
	// TODO: 在此添加消息处理程序代码和/或调用默认值

	//CWnd::OnKeyDown(nChar, nRepCnt, nFlags);
	std::string str;
	key_translate(str, nChar);
	if (!str.empty())
		canvas.message(str.c_str(), 1);

}


void CLuaCanvasView::OnKeyUp(UINT nChar, UINT nRepCnt, UINT nFlags)
{
	// TODO: 在此添加消息处理程序代码和/或调用默认值

	//CWnd::OnKeyUp(nChar, nRepCnt, nFlags);
	std::string str;
	key_translate(str, nChar);
	if (!str.empty())
		canvas.message(str.c_str(), 0);

}
