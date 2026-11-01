{*************************************************************************************
  This file is part of Transmission Remote GUI.
  Copyright (c) 2008-2019 by Yury Sidorov and Transmission Remote GUI working group.

  Transmission Remote GUI is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  Transmission Remote GUI is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Transmission Remote GUI; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

  In addition, as a special exception, the copyright holders give permission to
  link the code of portions of this program with the
  OpenSSL library under certain conditions as described in each individual
  source file, and distribute linked combinations including the two.

  You must obey the GNU General Public License in all respects for all of the
  code used other than OpenSSL.  If you modify file(s) with this exception, you
  may extend this exception to your version of the file(s), but you are not
  obligated to do so.  If you do not wish to do so, delete this exception
  statement from your version.  If you delete this exception statement from all
  source files in the program, then also delete it here.
*************************************************************************************}
unit ConfirmDlg;

{$mode objfpc}{$H+}
{$ifdef darwin}
{$modeswitch objectivec2}
{$endif darwin}

interface

{ Shows a Yes/No confirmation with a check box below the message.
  "No" is the default button and Escape cancels the dialog.
  Checked is used as the initial check box state and receives the final state.
  Returns True if the user pressed "Yes". }
function ConfirmWithCheckBox(const Msg, CheckBoxCaption: string; var Checked: boolean): boolean;

implementation

uses
{$ifdef darwin}
  CocoaAll, CocoaUtils, CocoaConst, CocoaMenus, LCLType;
{$else}
  Classes, Controls, Forms, Dialogs, StdCtrls, Buttons, Math;
{$endif darwin}

{$ifdef darwin}

const
  kVK_Escape = $35;

type
  { Closes the alert with the "No" result on Escape, because "No" can not have
    both Return and Escape as key equivalents }
  TConfirmEscapeView = objcclass(NSView)
    function performKeyEquivalent(theEvent: NSEvent): ObjCBOOL; override;
  end;

function TConfirmEscapeView.performKeyEquivalent(theEvent: NSEvent): ObjCBOOL;
begin
  if theEvent.keyCode = kVK_Escape then
  begin
    NSApplication(NSApp).stopModalWithCode(NSAlertSecondButtonReturn);
    Result := True;
  end
  else
    Result := inherited performKeyEquivalent(theEvent);
end;

function ConfirmWithCheckBox(const Msg, CheckBoxCaption: string; var Checked: boolean): boolean;
var
  alert: NSAlert;
  escView: TConfirmEscapeView;
  btn: NSButton;
  s: NSString;
  res: NSInteger;
  isMenuOn: boolean;
begin
  alert := NSAlert.alloc.init;
  escView := TConfirmEscapeView.alloc.init;
  try
    alert.setMessageText(NSSTR_EMPTY);
    s := NSStringUtf8(Msg);
    alert.setInformativeText(s);
    s.release;

    btn := alert.addButtonWithTitle(BUTTON_CAPTION_ARRAY[idButtonYes]);
    btn.setKeyEquivalent(NSSTR_EMPTY);
    btn := alert.addButtonWithTitle(BUTTON_CAPTION_ARRAY[idButtonNo]);
    btn.setKeyEquivalentModifierMask(0);
    btn.setKeyEquivalent(NSSTR_KEY_ENTER);

    escView.setBounds(NSZeroRect);
    alert.setAccessoryView(escView);

    alert.setShowsSuppressionButton(True);
    s := NSStringUtf8(CheckBoxCaption);
    alert.suppressionButton.setTitle(s);
    s.release;
    if Checked then
      alert.suppressionButton.setState(NSOnState)
    else
      alert.suppressionButton.setState(NSOffState);

    // The application menu must not be usable while the alert is shown
    isMenuOn := TCocoaMenuUtil.toggleAppMenu(False);
    try
      res := alert.runModal;
    finally
      TCocoaMenuUtil.toggleAppMenu(isMenuOn);
    end;

    Result := res = NSAlertFirstButtonReturn;
    Checked := alert.suppressionButton.state = NSOnState;
  finally
    escView.release;
    alert.release;
  end;
end;

{$else}

function ConfirmWithCheckBox(const Msg, CheckBoxCaption: string; var Checked: boolean): boolean;
var
  dlg: TForm;
  cb: TCheckBox;
  btn: TBitBtn;
  i, btnTop, btnLeft, btnWidth, spacing: integer;
begin
  dlg := CreateMessageDialog(Msg, mtConfirmation, [mbYes, mbNo]);
  try
    spacing := dlg.Scale96ToFont(8);
    btnTop := 0;
    btnWidth := 0;
    for i := 0 to dlg.ComponentCount - 1 do
      if dlg.Components[i] is TBitBtn then
      begin
        btn := TBitBtn(dlg.Components[i]);
        btnTop := btn.Top;
        Inc(btnWidth, btn.Width + spacing);
        btn.Default := btn.ModalResult = mrNo;
        if btn.Default then
          dlg.ActiveControl := btn;
      end;
    Dec(btnWidth, spacing);

    // Insert the check box between the message and the buttons
    cb := TCheckBox.Create(dlg);
    cb.Parent := dlg;
    cb.Caption := CheckBoxCaption;
    cb.Checked := Checked;
    cb.AutoSize := True;
    cb.HandleNeeded;
    cb.AdjustSize;
    cb.Top := btnTop;

    dlg.ClientWidth := Max(dlg.ClientWidth, cb.Width + 4 * spacing);
    dlg.ClientHeight := dlg.ClientHeight + cb.Height + spacing;
    cb.Left := (dlg.ClientWidth - cb.Width) div 2;

    btnLeft := (dlg.ClientWidth - btnWidth) div 2;
    for i := 0 to dlg.ComponentCount - 1 do
      if dlg.Components[i] is TBitBtn then
      begin
        btn := TBitBtn(dlg.Components[i]);
        btn.SetBounds(btnLeft, btnTop + cb.Height + spacing, btn.Width, btn.Height);
        Inc(btnLeft, btn.Width + spacing);
      end;

    Result := dlg.ShowModal = mrYes;
    Checked := cb.Checked;
  finally
    dlg.Free;
  end;
end;

{$endif darwin}

end.
