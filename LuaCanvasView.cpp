
// LuaCanvasView.cpp : implementation of the CLuaCanvasView class
//

#include "stdafx.h"
#include "LuaCanvas.h"
#include "LuaCanvasView.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


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
	//TODO change title
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
			canvas.load(str, dc, rect);

			ReleaseDC(dc);
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


//void CLuaCanvasView::OnSizing(UINT fwSide, LPRECT pRect)
//{
//	//CWnd::OnSizing(fwSide, pRect);
//
//}
