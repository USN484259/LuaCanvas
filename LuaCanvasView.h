
// LuaCanvasView.h : interface of the CLuaCanvasView class
//


#pragma once

#include "canvas.h"
#include <unordered_map>
#include <string>

// CLuaCanvasView window

class CLuaCanvasView : public CWnd
{
	Canvas canvas;
	UINT_PTR timer;
	DWORD interval;
// Construction
public:
	CLuaCanvasView();

// Attributes
private:
	static const std::unordered_map<UINT, const char*> key_mapping;

public:

// Operations
private:
	void timer_set(DWORD);
	void title(LPCTSTR);
	void redraw(void);
	static void key_translate(std::string&,UINT);
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
	afx_msg void OnKeyDown(UINT nChar, UINT nRepCnt, UINT nFlags);
	afx_msg void OnKeyUp(UINT nChar, UINT nRepCnt, UINT nFlags);
	afx_msg void OnLButtonDown(UINT nFlags, CPoint point);
	afx_msg void OnLButtonUp(UINT nFlags, CPoint point);
	afx_msg void OnMButtonDown(UINT nFlags, CPoint point);
	afx_msg void OnMButtonUp(UINT nFlags, CPoint point);
	afx_msg void OnRButtonDown(UINT nFlags, CPoint point);
	afx_msg void OnRButtonUp(UINT nFlags, CPoint point);
	afx_msg BOOL OnMouseWheel(UINT nFlags, short zDelta, CPoint pt);
	afx_msg void OnMouseMove(UINT nFlags, CPoint point);
};

