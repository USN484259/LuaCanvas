
// LuaCanvasView.h : interface of the CLuaCanvasView class
//


#pragma once

#include "canvas.h"

// CLuaCanvasView window

class CLuaCanvasView : public CWnd
{
	Canvas canvas;
	UINT_PTR timer;
// Construction
public:
	CLuaCanvasView();

// Attributes
public:

// Operations
private:
	void timer_stop(void);
	void timer_start(DWORD);
	void title(LPCTSTR);
public:
	static void on_report(const char*, void*);

// Overrides
	protected:
	virtual BOOL PreCreateWindow(CREATESTRUCT& cs);

// Implementation
public:
	virtual ~CLuaCanvasView();

	// Generated message map functions
protected:
	afx_msg void OnPaint();
	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnCanvasClear();
	afx_msg void OnCanvasDraw();
	afx_msg void OnFileClose();
	afx_msg void OnFileOpen();
	afx_msg BOOL OnEraseBkgnd(CDC* pDC);
	afx_msg void OnClose();
	afx_msg void OnTimer(UINT_PTR nIDEvent);
//	afx_msg void OnSizing(UINT fwSide, LPRECT pRect);
};

