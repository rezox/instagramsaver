unit UnitMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, JvComponentBase, JvUrlListGrabber, JvUrlGrabbers, StrUtils,
  Vcl.Mask, sSkinProvider, sSkinManager, sMaskEdit,
  sCustomComboEdit, sToolEdit, Vcl.Buttons, sBitBtn, sEdit, Vcl.ComCtrls,
  sStatusBar, sGauge, sBevel, sPanel, JvComputerInfoEx, IniFiles, sLabel, ShellAPI, windows7taskbar, UnitImageTypeExtractor,
  Generics.Collections, JvThread, Vcl.Menus, UnitPhotoDownloaderThread, System.Types;

type
  TURLType = (Img=0, Video=1);

type
  TURL = packed record
    URL: string;
    URLType: TURLType;
  end;

type
  TMainForm = class(TForm)
    ImagePageDownloader1: TJvHttpUrlGrabber;
    ImagePageDownloader2: TJvHttpUrlGrabber;
    GroupBox1: TGroupBox;
    ProgressEdit: TsEdit;
    OutputEdit: TsDirectoryEdit;
    OpenOutputBtn: TsBitBtn;
    sSkinManager1: TsSkinManager;
    sSkinProvider1: TsSkinProvider;
    TotalBar: TsGauge;
    sPanel1: TsPanel;
    DownloadBtn: TsBitBtn;
    StopBtn: TsBitBtn;
    AboutBtn: TsBitBtn;
    SettingsBtn: TsBitBtn;
    sPanel2: TsPanel;
    UserNameEdit: TsEdit;
    Info: TJvComputerInfoEx;
    CurrentLinkEdit: TsLabel;
    StateEdit: TsLabel;
    DonateBtn: TsBitBtn;
    LogBtn: TsBitBtn;
    VideoLinkDownloader2: TJvHttpUrlGrabber;
    VideoLinkDownloader1: TJvHttpUrlGrabber;
    UpdateThread: TJvThread;
    UpdateDownloader: TJvHttpUrlGrabber;
    AboutMenu: TPopupMenu;
    A1: TMenuItem;
    c1: TMenuItem;
    H1: TMenuItem;
    PosTimer: TTimer;
    sStatusBar1: TsStatusBar;
    TimeTimer: TTimer;
    R1: TMenuItem;
    procedure DownloadBtnClick(Sender: TObject);
    procedure ImagePageDownloader1DoneFile(Sender: TObject; FileName: string; FileSize: Integer; Url: string);
    procedure ImagePageDownloader2DoneFile(Sender: TObject; FileName: string; FileSize: Integer; Url: string);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StopBtnClick(Sender: TObject);
    procedure SettingsBtnClick(Sender: TObject);
    procedure OpenOutputBtnClick(Sender: TObject);
    procedure UserNameEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AboutBtnClick(Sender: TObject);
    procedure DonateBtnClick(Sender: TObject);
    procedure ImagePageDownloader2Error(Sender: TObject; ErrorMsg: string);
    procedure ImagePageDownloader1Error(Sender: TObject; ErrorMsg: string);
    procedure im1Error(Sender: TObject; ErrorMsg: string);
    procedure im2Error(Sender: TObject; ErrorMsg: string);
    procedure LogBtnClick(Sender: TObject);
    procedure VideoLinkDownloader1DoneFile(Sender: TObject; FileName: string;
      FileSize: Integer; Url: string);
    procedure VideoLinkDownloader2DoneFile(Sender: TObject; FileName: string;
      FileSize: Integer; Url: string);
    procedure VideoLinkDownloader1Error(Sender: TObject; ErrorMsg: string);
    procedure VideoLinkDownloader2Error(Sender: TObject; ErrorMsg: string);
    procedure VideoLinkDownloader1Progress(Sender: TObject; Position,
      TotalSize: Int64; Url: string; var Continue: Boolean);
    procedure VideoLinkDownloader2Progress(Sender: TObject; Position,
      TotalSize: Int64; Url: string; var Continue: Boolean);
    procedure UpdateThreadExecute(Sender: TObject; Params: Pointer);
    procedure UpdateDownloaderDoneStream(Sender: TObject; Stream: TStream;
      StreamSize: Integer; Url: string);
    procedure A1Click(Sender: TObject);
    procedure c1Click(Sender: TObject);
    procedure H1Click(Sender: TObject);
    procedure PosTimerTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure TimeTimerTimer(Sender: TObject);
    procedure R1Click(Sender: TObject);
  private
    { Private declarations }
    FImageIndex: integer;
    FVideoPageIndex: Integer;
    FTime: Integer;

    FLinksToDownload: TList<TURL>;
    FPageURLs: TStringList;
    FFilesToCheck: TStringList;

    FDownloadThreads: array[0..15] of TPhotoDownloadThread;
    FURLs: array[0..15] of  TStringList;
    FOutputFiles: array[0..15] of TStringList;
    FThreadCount: Integer;

    function LineToImageLink(const Line: string):string;
    function LinetoNextPageLink(const Line: string):string;
    function LineToPageLink(const Line: string): string;
    function LineToVideoURL(const Line: string): string;

    procedure LoadSettings;
    procedure SaveSettings;

    procedure DisableUI;
    procedure EnableUI;

    function URLToFileName(const URL: TURL): string;

    // returns true when no problem occurs
    function CheckFiles: Boolean;

    // generates guid
    function GenerateGUID: string;

    // checks if string is numeric
    function IsStringNumeric(Str: string): Boolean;

    // starts image/video downloader threads
    procedure LaunchDownloadThreads(const ThreadCount: Integer);

    // clears temp folder
    procedure ClearTempFolder;

    procedure AddToProgramLog(const Line: string);

    function IntegerToTime(const Time: Integer): string;
  public
    { Public declarations }
    FAppDataFolder: string;
    FTempFolder: string;
  end;

var
  MainForm: TMainForm;

const
  BuildInt = 235;
  Portable = False;

implementation

{$R *.dfm}

uses UnitSettings, UnitAbout, UnitLog;

procedure TMainForm.A1Click(Sender: TObject);
begin
  Self.Enabled := False;
  AboutForm.Show;
end;

procedure TMainForm.AboutBtnClick(Sender: TObject);
var
  P: TPoint;
begin
  P := AboutBtn.ClientToScreen(Point(0, 0));

  AboutMenu.Popup(P.X, P.Y + AboutBtn.Height)
end;

procedure TMainForm.AddToProgramLog(const Line: string);
begin
  if Length(Line) > 0 then
  begin
    LogForm.LogList.Lines.Add('[' + DateTimeToStr(Now) + '] ' + Line)
  end
  else
  begin
    LogForm.LogList.Lines.Add('');
  end;
end;

procedure TMainForm.c1Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', pwidechar(ExtractFileDir(Application.ExeName) + '\changelog.txt'), nil, nil, SW_SHOWNORMAL);
end;

function TMainForm.CheckFiles: Boolean;
var
  i: integer;
  LITE: TImageTypeEx;
begin
  Self.Caption := 'Checking downloaded images...';
  Self.Enabled := False;
  Result := False;
  try
    for I := 0 to FFilesToCheck.Count-1 do
    begin
      Application.ProcessMessages;
      Self.Caption := 'Checking downloaded images...(' + FloatToStr(i + 1) + '/' + FloatToStr(FFilesToCheck.Count) + ')';
      if FileExists(FFilesToCheck[i]) then
      begin
        // check file
        LITE := TImageTypeEx.Create(FFilesToCheck[i]);
        try
          if Length(LITE.ImageType) < 1 then
          begin
            AddToProgramLog('Invalid file: ' + FFilesToCheck[i]);
            Result := True;
          end;
        finally
          LITE.Free;
        end;
      end
      else
      begin
        AddToProgramLog('Unable to find file: ' + FFilesToCheck[i]);
        Result := True;
      end;
    end;
  finally
    Self.Caption := 'InstagramSaver';
    Self.Enabled := True
  end;
end;

procedure TMainForm.ClearTempFolder;
var
  Search: TSearchRec;
begin
  if DirectoryExists(FTempFolder) then
  begin
    if (FindFirst(FTempFolder + '\*.*', faAnyFile, Search) = 0) then
    Begin
      repeat
        Application.ProcessMessages;
        if (Search.Name = '.') or (Search.Name = '..') then
          Continue;
        if FileExists(FTempFolder + '\' + Search.Name) then
        begin
          DeleteFile(FTempFolder + '\' + Search.Name)
        end;
      until (FindNext(Search) <> 0);
      FindClose(Search);
    end;
  end;
end;

procedure TMainForm.DisableUI;
begin
  UserNameEdit.Enabled := False;
  DownloadBtn.Enabled := False;
  StopBtn.Enabled := True;
  SettingsBtn.Enabled := False;
  AboutBtn.Enabled := False;
  OutputEdit.Enabled := False;
end;

procedure TMainForm.DonateBtnClick(Sender: TObject);
begin
{<form action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_top">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="hosted_button_id" value="">
<input type="image" src="https://www.paypalobjects.com/tr_TR/TR/i/btn/btn_donateCC_LG.gif" border="0" name="submit" alt="PayPal - Online �deme yapman�n daha g�venli ve kolay yolu!">
<img alt="" border="0" src="https://www.paypalobjects.com/tr_TR/i/scr/pixel.gif" width="1" height="1">
</form>
}
ShellExecute(0, 'open', 'https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=6MSWEDR4AGBQG', nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.DownloadBtnClick(Sender: TObject);
begin
  if Length(UserNameEdit.Text) > 0 then
  begin
    if not ForceDirectories(OutputEdit.Text + '\' + UserNameEdit.Text) then
    begin
      Application.MessageBox('Cannot create output folder. Please enter a valid one.', 'Error', MB_ICONERROR);
      Exit;
    end;
    // reset lists
    FLinksToDownload.Clear;
    FFilesToCheck.Clear;
    FPageURLs.Clear;
    FTime := 0;

    // delete temp files
    if FileExists(ImagePageDownloader1.FileName) then
    begin
      DeleteFile(ImagePageDownloader1.FileName)
    end;
    if FileExists(ImagePageDownloader2.FileName) then
    begin
      DeleteFile(ImagePageDownloader2.FileName)
    end;
    if FileExists(VideoLinkDownloader2.FileName) then
    begin
      DeleteFile(VideoLinkDownloader2.FileName)
    end;
    if FileExists(VideoLinkDownloader1.FileName) then
    begin
      DeleteFile(VideoLinkDownloader1.FileName)
    end;

    TotalBar.Progress := 0;

    StateEdit.Caption := 'State: Extracting image links...';
    ProgressEdit.Text := '0/0';
    Self.Caption := '0% [InstagramSaver]';
    DisableUI;
    CurrentLinkEdit.Caption := 'Link: ' + 'http://web.stagram.com/n/' + UserNameEdit.Text + '/?vm=list';
    SetProgressState(Handle, tbpsNormal);

    AddToProgramLog('Starting to download user: ' + UserNameEdit.Text);
    AddToProgramLog('Extracting image links...');
    ImagePageDownloader1.Url := 'http://web.stagram.com/n/' + UserNameEdit.Text + '/?vm=list';
    ImagePageDownloader1.Start;
    TimeTimer.Enabled := True;
  end
  else
  begin
    Application.MessageBox('Please enter a user name first.', 'Error', MB_ICONERROR);
  end;
end;

procedure TMainForm.EnableUI;
begin
  TimeTimer.Enabled := False;
  UserNameEdit.Enabled := True;
  DownloadBtn.Enabled := True;
  StopBtn.Enabled := False;
  SettingsBtn.Enabled := True;
  AboutBtn.Enabled := True;
  OutputEdit.Enabled := True;
  TotalBar.Progress := 0;
  CurrentLinkEdit.Caption := 'Link: ';
  StateEdit.Caption := 'State: ';
  Self.Caption := 'InstagramSaver';
  SetProgressValue(Handle, 0, MaxInt);
  SetProgressState(Handle, tbpsNone);
  sStatusBar1.Panels[2].Text := '00:00:00';
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettings;
  // delete temp files
  if FileExists(ImagePageDownloader1.FileName) then
  begin
    DeleteFile(ImagePageDownloader1.FileName)
  end;
  if FileExists(ImagePageDownloader2.FileName) then
  begin
    DeleteFile(ImagePageDownloader2.FileName)
  end;
  if FileExists(VideoLinkDownloader2.FileName) then
  begin
    DeleteFile(VideoLinkDownloader2.FileName)
  end;
  if FileExists(VideoLinkDownloader1.FileName) then
  begin
    DeleteFile(VideoLinkDownloader1.FileName)
  end;
  if Portable then
  begin
    if DirectoryExists(FTempFolder) then
    begin
      RemoveDir(FTempFolder);
    end;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  FLinksToDownload := TList<TURL>.Create;
  FPageURLs := TStringList.Create;
  FFilesToCheck := TStringList.Create;
  for I := Low(FURLs) to High(FURLs) do
  begin
    FURLs[i] := TStringList.Create;
    FOutputFiles[i] := TStringList.Create;
  end;

  if Portable then
  begin
    FAppDataFolder := ExtractFileDir(Application.ExeName) + '\'
  end
  else
  begin
    FAppDataFolder := Info.Folders.AppData + '\InstagramSaver\';
  end;
  FTempFolder := Info.Folders.Temp + '\InstagramSaver\';
  if not DirectoryExists(FAppDataFolder) then
  begin
    CreateDir(FAppDataFolder);
  end;
  if not DirectoryExists(FTempFolder) then
  begin
    CreateDir(FTempFolder);
  end;
  ImagePageDownloader1.FileName := FTempFolder + '\' + GenerateGUID + '.txt';
  ImagePageDownloader2.FileName := FTempFolder + '\' + GenerateGUID + '.txt';
  VideoLinkDownloader2.FileName := FTempFolder + '\' + GenerateGUID + '.txt';
  VideoLinkDownloader1.FileName := FTempFolder + '\' + GenerateGUID + '.txt';

  // windows 7 taskbar
  if CheckWin32Version(6, 1) then
  begin
    if not InitializeTaskbarAPI then
    begin
      Application.MessageBox('You seem to have Windows 7 but program can''t start taskbar progressbar!', 'Error', MB_ICONERROR);
    end;
  end;
  ClearTempFolder;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  i: Integer;
begin
  FLinksToDownload.Free;
  FPageURLs.Free;
  FFilesToCheck.Free;
  for I := Low(FURLs) to High(FURLs) do
  begin
    FURLs[i].Free;
    FOutputFiles[i].Free;
  end;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  sStatusBar1.Panels[1].Width := sStatusBar1.ClientWidth - (sStatusBar1.Panels[0].Width + sStatusBar1.Panels[2].Width)
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  LoadSettings;
end;

function TMainForm.GenerateGUID: string;
var
  LGUID: TGUID;
begin
  CreateGUID(LGUID);
  Result := GUIDToString(LGUID);
end;

procedure TMainForm.H1Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'https://sourceforge.net/projects/instagramsaver/', nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.im1Error(Sender: TObject; ErrorMsg: string);
begin
  LogForm.LogList.Lines.Add('ID1: ' + ErrorMsg);
end;

procedure TMainForm.im2Error(Sender: TObject; ErrorMsg: string);
begin
  LogForm.LogList.Lines.Add('ID2: ' + ErrorMsg);
end;

procedure TMainForm.ImagePageDownloader1DoneFile(Sender: TObject; FileName: string; FileSize: Integer; Url: string);
const
  ImageLink = '.jpg';
  ImageLink2 = '<a href="/p/';
  NextPageLink = 'npk';
  Grid = 'vm=grid&';
  List = 'vm=list&';
  NextText = 'rel="next">';
  LargeImg = 'pw:image="';
  PageURLStart = 'pw:url="';
var
  LStreamReader: TStreamReader;
  LLine: string;
  LNextPageLink: string;
  i:integer;
  LURL: TURL;
begin
  // if StreamSize > 0 then
  // begin
  LStreamReader := TStreamReader.Create(FileName, True);
  LNextPageLink := '';
  try
    while not LStreamReader.EndOfStream do
    begin
      LLine := Trim(LStreamReader.ReadLine);
      // image link
      if ContainsText(LLine, LargeImg) then
      begin
        if ('htt' = Copy(LineToImageLink(LLine), 1, 3)) then
        begin
          LURL.URL := LineToImageLink(LLine);
          LURL.URLType := Img;
          FLinksToDownload.Add(LURL);
        end;
      end;
      // page link
      if ContainsText(LLine, PageURLStart) then
      begin
        FPageURLs.Add(LineToPageLink(LLine))
      end;
      // next page
      if ContainsText(LLine, NextPageLink) and ContainsText(LLine, NextText) then
      begin
        LNextPageLink := LinetoNextPageLink(LLine);
        if not ('htt' = Copy(LNextPageLink, 1, 3)) then
        begin
          LNextPageLink := '';
        end
        else
        begin
          ProgressEdit.Text := '0/' + FloatToStr(FLinksToDownload.Count);
        end;
      end;
    end;
  finally
    LStreamReader.Close;
    LStreamReader.Free;
  end;

  if (Length(LNextPageLink) > 0) then
  begin
    ImagePageDownloader2.Url := LNextPageLink;
    CurrentLinkEdit.Caption := 'Link: ' + LNextPageLink;
    ImagePageDownloader2.Start;
  end
  else
  begin
    ProgressEdit.Text := '0/' + FloatToStr(FLinksToDownload.Count);

    for I := 0 to FLinksToDownload.Count-1 do
    begin
      LURL := FLinksToDownload[i];
      LURL.URL := StringReplace(LURL.URL, 'a.jpg', 'n.jpg', [rfReplaceAll]);
      FLinksToDownload[i] := LURL;
    end;

    if SettingsForm.DownloadVideoBtn.Checked then
    begin
      if FPageURLs.Count > 0 then
      begin
        // search for video links
        StateEdit.Caption := 'State: Extracting video links...';
        FVideoPageIndex := 0;
        AddToProgramLog('Searching for video links...');
        CurrentLinkEdit.Caption := 'Link: ' + FPageURLs[FVideoPageIndex];
        VideoLinkDownloader1.Url := FPageURLs[FVideoPageIndex];
        VideoLinkDownloader1.Start;
      end
      else
      begin
        Application.MessageBox('No links were extracted.', 'Error', MB_ICONERROR);
        EnableUI;
      end;
    end
    else
    begin
      // start downloading
      if FLinksToDownload.Count > 0 then
      begin
        StateEdit.Caption := 'State: Downloading...';
        FImageIndex := 0;
        // parallel download count
        FThreadCount := SettingsForm.ThreadList.ItemIndex+1;
        if FThreadCount > FLinksToDownload.Count then
        begin
          FThreadCount := FLinksToDownload.Count;
        end;
        LaunchDownloadThreads(FThreadCount);
      end
      else
      begin
        Application.MessageBox('No links were extracted.', 'Error', MB_ICONERROR);
        EnableUI;
      end;
    end;
  end;

end;

procedure TMainForm.ImagePageDownloader1Error(Sender: TObject;
  ErrorMsg: string);
begin
  LogForm.LogList.Lines.Add('IPD1: ' + ErrorMsg);
end;

procedure TMainForm.ImagePageDownloader2DoneFile(Sender: TObject; FileName: string;
  FileSize: Integer; Url: string);
const
  ImageLink = '.jpg';
  ImageLink2 = '<a href="/p/';
  NextPageLink = 'npk';
  Grid = 'vm=grid&';
  List = 'vm=list&';
  NextText = 'rel="next">';
  SmallerImgStart = 'scontent';
  LargeImg = 'pw:image="';
  VideoLineStartStr = '<div id="jquery_jplayer_1" class="jp-jplayer"';
  PageURLStart = 'pw:url="';
var
  LStreamReader: TStreamReader;
  LLine: string;
  LNextPageLink: string;
  i:integer;
  LURL: TURL;
begin
  // if StreamSize > 0 then
  // begin
  LStreamReader := TStreamReader.Create(FileName, True);
  LNextPageLink := '';
  try
    while not LStreamReader.EndOfStream do
    begin
      LLine := Trim(LStreamReader.ReadLine);
      // image link
      if ContainsText(LLine, LargeImg) then
      begin
        if ('htt' = Copy(LineToImageLink(LLine), 1, 3)) then
        begin
          LURL.URL := LineToImageLink(LLine);
          LURL.URLType := Img;
          FLinksToDownload.Add(LURL);
        end;
      end;
      // page link
      if ContainsText(LLine, PageURLStart) then
      begin
        FPageURLs.Add(LineToPageLink(LLine))
      end;
      // next page
      if ContainsText(LLine, NextPageLink) and ContainsText(LLine, NextText) then
      begin
        LNextPageLink := LinetoNextPageLink(LLine);
        if not ('htt' = Copy(LNextPageLink, 1, 3)) then
        begin
          LNextPageLink := '';
        end
        else
        begin
          ProgressEdit.Text := '0/' + FloatToStr(FLinksToDownload.Count);
        end;
      end;
    end;
  finally
    LStreamReader.Close;
    LStreamReader.Free;
  end;

  if (Length(LNextPageLink) > 0) then
  begin
    ImagePageDownloader1.Url := LNextPageLink;
    CurrentLinkEdit.Caption := 'Link: ' + LNextPageLink;
    ImagePageDownloader1.Start;
  end
  else
  begin
    ProgressEdit.Text := '0/' + FloatToStr(FLinksToDownload.Count);

    for I := 0 to FLinksToDownload.Count-1 do
    begin
      LURL := FLinksToDownload[i];
      LURL.URL := StringReplace(LURL.URL, 'a.jpg', 'n.jpg', [rfReplaceAll]);
      FLinksToDownload[i] := LURL;
    end;

    if SettingsForm.DownloadVideoBtn.Checked then
    begin
      if FPageURLs.Count > 0 then
      begin
        // search for video links
        StateEdit.Caption := 'State: Extracting video links...';
        FVideoPageIndex := 0;
        AddToProgramLog('Searching for video links...');
        CurrentLinkEdit.Caption := 'Link: ' + FPageURLs[FVideoPageIndex];
        VideoLinkDownloader1.Url := FPageURLs[FVideoPageIndex];
        VideoLinkDownloader1.Start;
      end
      else
      begin
        Application.MessageBox('No links were extracted.', 'Error', MB_ICONERROR);
        EnableUI;
      end;
    end
    else
    begin
      // start downloading
      if FLinksToDownload.Count > 0 then
      begin
        StateEdit.Caption := 'State: Downloading...';
        FImageIndex := 0;
        // parallel download count
        FThreadCount := SettingsForm.ThreadList.ItemIndex+1;
        if FThreadCount > FLinksToDownload.Count then
        begin
          FThreadCount := FLinksToDownload.Count;
        end;
        LaunchDownloadThreads(FThreadCount);
      end
      else
      begin
        Application.MessageBox('No links were extracted.', 'Error', MB_ICONERROR);
        EnableUI;
      end;
    end;
  end;

end;

procedure TMainForm.ImagePageDownloader2Error(Sender: TObject;
  ErrorMsg: string);
begin
  LogForm.LogList.Lines.Add('IPD2: ' + ErrorMsg);
end;

function TMainForm.IntegerToTime(const Time: Integer): string;
var
  LHourStr, LMinStr, LSecStr: string;
  LHour, LMin, LSec: Integer;
begin
  Result := '00:00:00';
  if Time > 0 then
  begin
    LHour := Time div 3600;
    LMin := (Time div 60) - (LHour * 60);
    LSec := (Time mod 60);
    if LSec < 10 then
    begin
      LSecStr := '0' + FloatToStr(LSec)
    end
    else
    begin
      LSecStr := FloatToStr(LSec)
    end;
    if LMin < 10 then
    begin
      LMinStr := '0' + FloatToStr(LMin)
    end
    else
    begin
      LMinStr := FloatToStr(LMin)
    end;
    if LHour < 10 then
    begin
      LHourStr := '0' + FloatToStr(LHour)
    end
    else
    begin
      LHourStr := FloatToStr(LHour)
    end;
    Result := LHourStr + ':' + LMinStr + ':' + LSecStr;
  end;
end;

function TMainForm.IsStringNumeric(Str: string): Boolean;
var
  P: PChar;
begin

  if Length(Str) < 1 then
  begin
    Result := False;
    Exit;
  end;

  P := PChar(Str);
  Result := False;

  while P^ <> #0 do
  begin
    Application.ProcessMessages;

    if (Not CharInSet(P^, ['0' .. '9'])) then
    begin
      Exit;
    end;

    Inc(P);
  end;

  Result := True;
end;

procedure TMainForm.LaunchDownloadThreads(const ThreadCount: Integer);
var
  I: Integer;
begin
  AddToProgramLog('Starting to download.');
  AddToProgramLog(Format('Using %d threads.', [ThreadCount]));

  // clear lists
  for I := Low(FURLs) to High(FURLs) do
  begin
    FURLs[i].Clear;
    FOutputFiles[i].Clear;
  end;
  // add links and files to lists
  for I := 0 to FLinksToDownload.Count-1 do
  begin
    FURLs[i mod ThreadCount].Add(FLinksToDownload[i].URL);
    FOutputFiles[i mod ThreadCount].Add(ExcludeTrailingPathDelimiter(OutputEdit.Text) + '\' + UserNameEdit.Text + '\' + URLToFileName(FLinksToDownload[i]));
    FFilesToCheck.Add(ExcludeTrailingPathDelimiter(OutputEdit.Text) + '\' + UserNameEdit.Text + '\' + URLToFileName(FLinksToDownload[i]));
  end;
  // create threads
  for I := 0 to ThreadCount-1 do
  begin
    FDownloadThreads[i] := TPhotoDownloadThread.Create(FURLs[i], FOutputFiles[i]);
    FDownloadThreads[i].ID := i;
    FDownloadThreads[i].DontDoubleDownload := SettingsForm.DontDoubleDownloadBtn.Checked;
  end;

  PosTimer.Enabled := True;
end;

function TMainForm.LineToImageLink(const Line: string): string;
const
  ImgSrc = '<div class="social_buttons pw-widget pw-size-medium pw-counter-show" pw:image="';
  WidthStr = '.jpg';
var
  Pos2: integer;
  LTmpStr: string;
begin
  Result := Line;
  LTmpStr := Line;
  LTmpStr := StringReplace(LTmpStr, ImgSrc, '', [rfReplaceAll, rfIgnoreCase]);
  Pos2 := Pos(WidthStr, LTmpStr);
  if Pos2 > 0 then
  begin
    Result := Copy(LTmpStr, 1, Pos2+3);
  end;
end;

function TMainForm.LinetoNextPageLink(const Line: string): string;
const
  StartStr = '<li><a href="';
  LastStr = '" rel="next">';
  StartStr2 = '<a href="';
  LastStr2 = '" class="';
var
  Pos1: integer;
  Pos2: integer;
  LLink: string;
  LUnderLinePos: Integer;
begin
  Result := Line;

  if StartStr = Copy(Line, 1, Length(StartStr)) then
  begin
    Pos1 :=  Pos(StartStr, Line);
    Pos2 := Pos(LastStr, Line);
    if Pos2 > Pos1 then
    begin
      LLink := Copy(Line, Pos1+Length(StartStr), Pos2-Pos1-Length(LastStr)-1);
    end;
  end
  else
  begin
    Pos1 := Pos(StartStr2, Line);
    Pos2 := Pos(LastStr2, Line);
    if Pos2 > Pos1 then
    begin
      LLink := Copy(Line, Pos1+Length(StartStr2), Pos2-Pos1-Length(LastStr2)-1);
    end;
  end;
  LLink := StringReplace(LLink, 'vm=grid&', '', [rfReplaceAll]);
  LLink := StringReplace(LLink, 'vm=list&', '', [rfReplaceAll]);
  LLink := StringReplace(LLink, 'https', 'http', [rfReplaceAll]);
  LLink := ReverseString(LLink);
  LUnderLinePos := Pos('_', LLink);
  if LUnderLinePos > 0 then
  begin
    LLink := Copy(LLink, LUnderLinePos+1, MaxInt);
  end;
  LLink := ReverseString(LLink);
  if Length(LLink) > 0 then
  begin
    Result := 'http://web.stagram.com' + LLink;
  end;
end;

function TMainForm.LineToPageLink(const Line: string): string;
var
  Pos1, Pos2: integer;
  LTmpStr: string;
begin
  Result := Line;
  LTmpStr := Line;
  Pos1 := PosEx('pw:url="', Line);
  Pos2 := PosEx('" pw:twitter-via="', Line);
  if Pos2 > Pos1 then
  begin
    Result := Copy(Line, Pos1+8, Pos2-Pos1-8);
  end;
end;

function TMainForm.LineToVideoURL(const Line: string): string;
const
  Start = 'data-m4v="';
  EndStr = '"></div>';
var
  Pos1, Pos2: integer;
  LTmpStr: string;
begin
  Result := Line;
  LTmpStr := Line;
  Pos1 := PosEx(Start, LTmpStr);
  Pos2 := PosEx(EndStr, LTmpStr);
  if Pos2 > Pos1 then
  begin
    Result := Copy(LTmpStr, Pos1+Length(Start), Pos2-Pos1-Length(Start));
  end;
end;

procedure TMainForm.LoadSettings;
var
  LSetFile: TIniFile;
begin
  LSetFile := TIniFile.Create(FAppDataFolder + 'settings.ini');
  try
    with LSetFile do
    begin
      if Portable then
      begin
        OutputEdit.Text := ReadString('general', 'output', ExtractFileDir(Application.ExeName));
      end
      else
      begin
        OutputEdit.Text := ReadString('general', 'output', Info.Folders.Personal + '\InstagramSaver');
      end;

      // check update
      if ReadBool('general', 'update', True) then
      begin
        UpdateThread.Execute(nil);
      end;
      // skins
      case ReadInteger('general', 'skin', 0) of
        0:
          sSkinManager1.SkinName := 'DarkMetro (internal)';
        1:
          sSkinManager1.SkinName := 'AlterMetro (internal)';
      end;
    end;
  finally
    LSetFile.Free;
  end;
end;

procedure TMainForm.LogBtnClick(Sender: TObject);
begin
  LogForm.Show;
end;

procedure TMainForm.OpenOutputBtnClick(Sender: TObject);
begin
  if DirectoryExists(OutputEdit.Text) then
  begin
    ShellExecute(Handle, 'open', PWideChar(OutputEdit.Text), nil, nil, SW_SHOWNORMAL);
  end;
end;

procedure TMainForm.PosTimerTimer(Sender: TObject);
var
  LStillRunning: Boolean;
  I: Integer;
  LTotalProgress: Integer;
  LCurURL: string;
begin
  LStillRunning := False;
  LTotalProgress := 0;

  for I := Low(FDownloadThreads) to High(FDownloadThreads) do
  begin
    if Assigned(FDownloadThreads[i]) then
    begin
      LStillRunning := LStillRunning or (FDownloadThreads[i].Status = downloading);
      Inc(LTotalProgress, FDownloadThreads[i].Progress);
    end;
  end;

  if LStillRunning then
  begin
    // continue
    TotalBar.Progress := (100 * LTotalProgress) div FLinksToDownload.Count;
    ProgressEdit.Text := FloatToStr(LTotalProgress) + '/' + FloatToStr(FLinksToDownload.Count);
    Self.Caption := FloatToStr(TotalBar.Progress) + '% [InstagramSaver]';
    SetProgressValue(Handle, LTotalProgress, FLinksToDownload.Count);

    Randomize;
    LCurURL := FDownloadThreads[Random(FThreadCount)].CurrentURL;
    if Length(LCurURL) > 0 then
    begin
      CurrentLinkEdit.Caption := 'Link: ' + LCurURL;
    end;
  end
  else
  begin
    // done
    PosTimer.Enabled := False;
    AddToProgramLog(Format('Finished downloading in %s.', [IntegerToTime(FTime)]));
    AddToProgramLog('');
    EnableUI;
    Self.BringToFront;
    if SettingsForm.OpenOutBtn.Checked then
    begin
      ShellExecute(Handle, 'open', PWideChar(OutputEdit.Text + '\' + UserNameEdit.Text), nil, nil, SW_SHOWNORMAL);
    end;

    Sleep(100);
    TotalBar.Progress := 0;
    ProgressEdit.Text := FloatToStr(FLinksToDownload.Count) + '/' + FloatToStr(FLinksToDownload.Count);
    if CheckFiles then
    begin
      LogForm.Show;
    end;
  end;
end;

procedure TMainForm.R1Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://sourceforge.net/p/instagramsaver/tickets/', nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.SaveSettings;
var
  LSetFile: TIniFile;
begin
  LSetFile := TIniFile.Create(FAppDataFolder + 'settings.ini');
  try
    with LSetFile do
    begin
      WriteString('general', 'output', OutputEdit.Text);
    end;
  finally
    LSetFile.Free;
  end;
end;

procedure TMainForm.SettingsBtnClick(Sender: TObject);
begin
  Self.Enabled := False;
  SettingsForm.Show;
end;

procedure TMainForm.StopBtnClick(Sender: TObject);
var
  I: Integer;
begin
  if ID_YES = Application.MessageBox('Stop downloading?', 'Stop', MB_ICONQUESTION or MB_YESNO) then
  begin
    PosTimer.Enabled := False;

    if ImagePageDownloader1.Status <> gsStopped then
    begin
      ImagePageDownloader1.Stop;
    end;
    if ImagePageDownloader2.Status <> gsStopped then
    begin
      ImagePageDownloader2.Stop;
    end;
    if VideoLinkDownloader2.Status <> gsStopped then
    begin
      VideoLinkDownloader2.Stop;
    end;
    if VideoLinkDownloader1.Status <> gsStopped then
    begin
      VideoLinkDownloader1.Stop;
    end;
    for I := Low(FDownloadThreads) to High(FDownloadThreads) do
    begin
      if Assigned(FDownloadThreads[i]) then
      begin
        FDownloadThreads[i].Stop;
      end
      else
      begin
        AddToProgramLog(FloatToStr(i));
      end;
    end;

    AddToProgramLog(Format('Download is stopped at %s.', [IntegerToTime(FTime)]));
    AddToProgramLog('');
    EnableUI;
  end;
end;

procedure TMainForm.TimeTimerTimer(Sender: TObject);
begin
  Inc(FTime);
  sStatusBar1.Panels[2].Text := IntegerToTime(FTime);
end;

procedure TMainForm.UpdateDownloaderDoneStream(Sender: TObject; Stream: TStream; StreamSize: Integer; Url: string);
var
  VersionFile: TStringList;
  LatestVersion: Integer;
begin
  VersionFile := TStringList.Create;
  try
    if StreamSize > 0 then
    begin
      VersionFile.LoadFromStream(Stream);
      if VersionFile.Count = 1 then
      begin
        if IsStringNumeric(VersionFile.Strings[0]) then
        begin
          LatestVersion := StrToInt(VersionFile.Strings[0]);
          if LatestVersion > BuildInt then
          begin
            if ID_YES = Application.MessageBox('There is a new version. Would you like to go homepage and download it?', 'New Version', MB_ICONQUESTION or MB_YESNO) then
            begin
              ShellExecute(Application.Handle, 'open', 'https://sourceforge.net/projects/instagramsaver/', nil, nil, SW_SHOWNORMAL);
            end;
          end;
        end;
      end;
    end;
  finally
    FreeAndNil(VersionFile);
  end;
end;

procedure TMainForm.UpdateThreadExecute(Sender: TObject; Params: Pointer);
begin
  UpdateDownloader.Url := 'http://sourceforge.net/projects/instagramsaver/files/version.txt/download';
  UpdateDownloader.Start;

  UpdateThread.CancelExecute;
end;

function TMainForm.URLToFileName(const URL: TURL): string;
var
  LURL: string;
begin
  Result := URL.URL;
  LURL := URL.URL;
  LURL := StringReplace(LURL, '/', '\', [rfReplaceAll]);
  case URL.URLType of
    Img: Result := ChangeFileExt(ExtractFileName(LURL), '.jpg');
    Video: Result := ChangeFileExt(ExtractFileName(LURL), '.mp4');
  end;
end;

procedure TMainForm.UserNameEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    DownloadBtnClick(Self);
  end;
end;

procedure TMainForm.VideoLinkDownloader1DoneFile(Sender: TObject; FileName: string; FileSize: Integer; Url: string);
const
  VideoLineStartStr = '<div id="jquery_jplayer_1" class="jp-jplayer"';
var
  LStreamReader: TStreamReader;
  LLine: string;
  LURL: TURL;
begin
  Inc(FVideoPageIndex);
  if FVideoPageIndex < FPageURLs.Count-1 then
  begin
    LStreamReader := TStreamReader.Create(FileName, True);
    try
      while not LStreamReader.EndOfStream do
      begin
        LLine := Trim(LStreamReader.ReadLine);
        if VideoLineStartStr = Copy(LLine, 1, Length(VideoLineStartStr)) then
        begin
          LURL.URL := LineToVideoURL(LLine);
          LURL.URLType := Video;
          FLinksToDownload.Add(LURL);
          ProgressEdit.Text := '0/' + FloatToStr(FLinksToDownload.Count);
        end;
      end;
    finally
      LStreamReader.Close;
      LStreamReader.Free;
    end;

    // run next video page link
    CurrentLinkEdit.Caption := 'Link: ' + FPageURLs[FVideoPageIndex];
    VideoLinkDownloader2.Url := FPageURLs[FVideoPageIndex];
    VideoLinkDownloader2.Start;
  end
  else
  begin
    // start downloading
    if FLinksToDownload.Count > 0 then
    begin
      StateEdit.Caption := 'State: Downloading...';
      FImageIndex := 0;
      // parallel download count
      FThreadCount := SettingsForm.ThreadList.ItemIndex+1;
      if FThreadCount > FLinksToDownload.Count then
      begin
        FThreadCount := FLinksToDownload.Count;
      end;
      LaunchDownloadThreads(FThreadCount);
    end
    else
    begin
      Application.MessageBox('No links were extracted.', 'Error', MB_ICONERROR);
      EnableUI;
    end;
  end;
end;

procedure TMainForm.VideoLinkDownloader1Error(Sender: TObject;
  ErrorMsg: string);
begin
  LogForm.LogList.Lines.Add('VPD1: ' + ErrorMsg);
end;

procedure TMainForm.VideoLinkDownloader1Progress(Sender: TObject; Position, TotalSize: Int64; Url: string; var Continue: Boolean);
begin
  TotalBar.Progress := (100 * FVideoPageIndex) div FPageURLs.Count;
end;

procedure TMainForm.VideoLinkDownloader2DoneFile(Sender: TObject;
  FileName: string; FileSize: Integer; Url: string);
const
  VideoLineStartStr = '<div id="jquery_jplayer_1" class="jp-jplayer"';
var
  LStreamReader: TStreamReader;
  LLine: string;
  LURL: TURL;
begin
  Inc(FVideoPageIndex);
  if FVideoPageIndex < FPageURLs.Count-1 then
  begin
    LStreamReader := TStreamReader.Create(FileName, True);
    try
      while not LStreamReader.EndOfStream do
      begin
        LLine := Trim(LStreamReader.ReadLine);
        if VideoLineStartStr = Copy(LLine, 1, Length(VideoLineStartStr)) then
        begin
          LURL.URL := LineToVideoURL(LLine);
          LURL.URLType := Video;
          FLinksToDownload.Add(LURL);
          ProgressEdit.Text := '0/' + FloatToStr(FLinksToDownload.Count);
        end;
      end;
    finally
      LStreamReader.Close;
      LStreamReader.Free;
    end;

    // run next video page link
    CurrentLinkEdit.Caption := 'Link: ' + FPageURLs[FVideoPageIndex];
    VideoLinkDownloader1.Url := FPageURLs[FVideoPageIndex];
    VideoLinkDownloader1.Start;
  end
  else
  begin
    // start downloading
    if FLinksToDownload.Count > 0 then
    begin
      StateEdit.Caption := 'State: Downloading...';
      FImageIndex := 0;
      // parallel download count
      FThreadCount := SettingsForm.ThreadList.ItemIndex+1;
      if FThreadCount > FLinksToDownload.Count then
      begin
        FThreadCount := FLinksToDownload.Count;
      end;
      LaunchDownloadThreads(FThreadCount);
    end
    else
    begin
      Application.MessageBox('No links were extracted.', 'Error', MB_ICONERROR);
      EnableUI;
    end;
  end;
end;

procedure TMainForm.VideoLinkDownloader2Error(Sender: TObject;
  ErrorMsg: string);
begin
  LogForm.LogList.Lines.Add('VPD2: ' + ErrorMsg);
end;

procedure TMainForm.VideoLinkDownloader2Progress(Sender: TObject; Position, TotalSize: Int64; Url: string; var Continue: Boolean);
begin
  TotalBar.Progress := (100 * FVideoPageIndex) div FPageURLs.Count;
end;

end.