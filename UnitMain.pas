unit UnitMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, JPEG, StdCtrls, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdHTTP, ExtCtrls, OleCtrls, SHDocVw, inifiles, Grids,
  ValEdit, FileCtrl, ComCtrls, Buttons, Menus, ImgList, IdAntiFreezeBase,
  IdAntiFreeze, IdFTP;

type
  TForm1 = class(TForm)
    WebBrowser1: TWebBrowser;
    ListBox1: TListBox;
    IdHTTP1: TIdHTTP;
    Memo1: TMemo;
    Label1: TLabel;
    StatusBar1: TStatusBar;
    Timer1: TTimer;
    Image1: TImage;
    Label2: TLabel;
    Shape1: TShape;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    SpeedButton1: TSpeedButton;
    PopupMenu1: TPopupMenu;
    English1: TMenuItem;
    Portugus1: TMenuItem;
    IdAntiFreeze1: TIdAntiFreeze;
    Panel1: TPanel;
    Image2: TImage;
    SpeedButton2: TSpeedButton;
    Timer2: TTimer;
    Timer3: TTimer;
    IdHTTP2: TIdHTTP;
    SpeedButton3: TSpeedButton;
    procedure abre_carta(sender: TObject);
    procedure salva_imagem(sender: TObject);
    procedure carrega_linguagem(sender: TObject);
    procedure porcentagem_titulo(sender:TObject);
    procedure WebBrowser1DocumentComplete(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);
    procedure FormShow(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure English1Click(Sender: TObject);
    procedure Portugus1Click(Sender: TObject);
    procedure ListBox1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListBox1DrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure Image2MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image2Click(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  colecao, posicao, repetidas, total_colecoes, contador_geral, baixadas_colecao: integer;
  cfg, sets, language: TIniFile;
  ultima_carta, lang: string;
  sigla, nome_colecao, sigla_mws, quantidade_cartas: array[0..1000] of string;

implementation

uses UnitDirectory, UnitAbout;

{$R *.dfm}

function retorna(nome, desejo: string):string;
var
  i,a: integer;
begin
  for i:=sets.ReadInteger('sets', 'total', 0) downto 1 do
  begin
    if nome_colecao[i] = nome then
    begin
      a:=i;
      break;
    end;
  end;
  if desejo = 'sigla' then
    result:=sigla[a]
  else if desejo = 'sigla_mws' then
    result:=sigla_mws[a];
end;

function traduz(texto:string):string;
begin
  result:=language.ReadString('lang', texto, 'lang_missing');
end;

procedure TForm1.porcentagem_titulo(sender:TObject);
var
  t,i: integer;
begin
  Caption:='MWS Pics Downloader';
  if Timer1.Enabled then
  begin
    t:=0;
    for i:=0 to ListBox1.Count-1 do
    begin
      if ListBox1.Selected[i] then
      begin
        t:=t+strtoint(quantidade_cartas[sets.ReadInteger('sets', 'total', 0)-i]);
      end;
    end;
    Caption:=Caption+' - '+traduz('baixando')+' '+inttostr(contador_geral+1)+' '+traduz('de')+' '+inttostr(t)+' - '+inttostr(round(100*contador_geral/t))+'%';
  end;
end;

procedure TForm1.carrega_linguagem(sender: TObject);
begin
  Label2.Caption:=traduz('diretorio_pics');
  BitBtn1.Caption:=traduz('iniciar_download');
  BitBtn2.Caption:=traduz('sobre');
  Form2.BitBtn1.Caption:=traduz('ok');
  Form2.BitBtn2.Caption:=traduz('cancelar');
  Form2.Caption:=traduz('diretorio');
  Form3.Label3.Caption:=traduz('about1')+' Everton Leite';
  Form3.Label4.Caption:=traduz('about2');
  Form3.Caption:=traduz('sobre');
  if timer1.Enabled=false then
    StatusBar1.Panels[1].Text:=traduz('parado');
  Image2.Hint:=traduz('dica');
  SpeedButton2.Hint:=traduz('atualizacao_disponivel');
  SpeedButton3.Hint:=traduz('atualizacao_disponivel');
end;

procedure Split
   (const Delimiter: Char;
    Input: string;
    const Strings: TStrings) ;
begin
   Assert(Assigned(Strings)) ;
   Strings.Clear;
   Strings.Delimiter := Delimiter;
   Strings.DelimitedText := Input;
end;

procedure TForm1.abre_carta(sender: tobject);
begin
  WebBrowser1.Navigate('http://magiccards.info/' + LowerCase(retorna(ListBox1.Items.Strings[colecao], 'sigla')) + '/en/' + inttostr(posicao) + '.html');
end;

procedure TForm1.salva_imagem(sender: TObject);
var
  ok: boolean;
var
  strm: Tmemorystream;
  imgjpg: TJpegImage;
  url, title, temp: string;
  a: TStringList;
  i: integer;
begin
  a := TStringList.Create;
  url := 'http://magiccards.info/scans/en/';
  temp := StringReplace(WebBrowser1.LocationURL, 'http://magiccards.info/', '', [rfReplaceAll, rfIgnoreCase]);
  split('/', temp, a);
  url := url + a[0] + '/' + inttostr(posicao) + '.jpg';
  title := WebBrowser1.LocationName;
  if title <> WebBrowser1.LocationURL then
  begin
    split(' ', title, a);
    i := 0;
    title := '';
    while i >= 0 do
    begin
      if a[i] = StringReplace(a[i], '(', '', [rfReplaceAll, rfIgnoreCase]) then
      begin
        if i > 0 then
          title := title + ' ';
        title := title + a[i];
        i := i + 1;
      end
      else
        i := -1;
    end;
    strm := Tmemorystream.Create;
    try
      ok:=true;
      try
        idhttp1.Get(url, strm);
      except
        ok:=false;
      end;
      if ok = true then
      begin
        strm.Position := 0;
        imgjpg := TJpegImage.Create;
        try
          imgjpg.LoadFromStream(Strm);
          if DirectoryExists(cfg.ReadString('system', 'diretory', 'c:\program files\magic workstation\pics')+ListBox1.Items.Strings[colecao])then
          begin
            if title = ultima_carta then
            begin
              repetidas := repetidas + 1;
              title := title + ' ('+inttostr(repetidas)+')';
            end
            else
            begin
              repetidas := 0;
              ultima_carta := title;
            end;
            imgjpg.SaveToFile(cfg.ReadString('system', 'diretory', 'c:\program files\magic workstation\pics') + retorna(ListBox1.Items.Strings[colecao], 'sigla_mws') + '\' + title + '.full.jpg');
            image1.Picture.LoadFromFile(cfg.ReadString('system', 'diretory', 'c:\program files\magic workstation\pics') + retorna(ListBox1.Items.Strings[colecao], 'sigla_mws') + '\' + title + '.full.jpg');
            Memo1.Lines.Add(language.ReadString('lang', 'baixado', 'lang_missing') + ': ' + title);
            baixadas_colecao:=baixadas_colecao+1;
            StatusBar1.Panels[1].Text:=traduz('baixando')+' '+ListBox1.Items.Strings[colecao]+'('+inttostr(baixadas_colecao)+' '+traduz('de')+' '+quantidade_cartas[sets.ReadInteger('sets', 'total', 0)-colecao]+')';
            porcentagem_titulo(self);
            posicao := posicao + 1;
            contador_geral:=contador_geral+1;
            abre_carta(self);
          end
          else
          begin
            try
              if title = ultima_carta then
              begin
                repetidas := repetidas + 1;
                title := title + ' ('+inttostr(repetidas)+')';
              end
              else
              begin
                repetidas := 0;
                ultima_carta := title;
              end;
              ForceDirectories(cfg.ReadString('system', 'diretory', 'c:\program files\magic workstation\pics')+retorna(ListBox1.Items.Strings[colecao], 'sigla_mws'));
              imgjpg.SaveToFile(cfg.ReadString('system', 'diretory', 'c:\program files\magic workstation\pics') + retorna(ListBox1.Items.Strings[colecao], 'sigla_mws') + '\' + title + '.full.jpg');
              image1.Picture.LoadFromFile(cfg.ReadString('system', 'diretory', 'c:\program files\magic workstation\pics') + retorna(ListBox1.Items.Strings[colecao], 'sigla_mws') + '\' + title + '.full.jpg');
              Memo1.Lines.Add(traduz('baixado')+ ': ' + title);
              baixadas_colecao:=baixadas_colecao+1;
              StatusBar1.Panels[1].Text:=traduz('baixando')+' '+ListBox1.Items.Strings[colecao]+'('+inttostr(baixadas_colecao)+' '+traduz('de')+' '+quantidade_cartas[sets.ReadInteger('sets', 'total', 0)-colecao]+')';
              porcentagem_titulo(self);
              posicao := posicao + 1;
              contador_geral:=contador_geral+1;
              abre_carta(self);
            except
              Application.MessageBox(PChar(traduz('problema_criacao_pasta')), PChar(traduz('atencao')), MB_OK+MB_ICONERROR);
            end
          end;
        finally
          imgjpg.Free;
        end;
      end;
    finally
      strm.Free;
    end;
  end
  else if baixadas_colecao < StrToInt(quantidade_cartas[sets.ReadInteger('sets', 'total', 0)-colecao]) then
  begin
    posicao:=posicao+1;
    abre_carta(self);
  end
  else
  begin
    if timer1.Enabled=true then
      Memo1.Lines.Add(traduz('download_de') + ' ' + ListBox1.Items.Strings[colecao] + ' '+traduz('completo')+'('+inttostr(baixadas_colecao)+' '+traduz('cartas')+')');
    baixadas_colecao:=0;
    StatusBar1.Panels[1].Text:=traduz('parado');
    BitBtn1.Visible:=true;
    BitBtn3.Visible:=false;
    ListBox1.Enabled:=true;
    StatusBar1.Panels.Items[0].Text:='';
    Timer1.Enabled:=false;
    porcentagem_titulo(self);
    if colecao < ListBox1.Count-1 then
    begin
      for colecao:=colecao+1 to ListBox1.Count-1 do
      begin
        if ListBox1.Selected[colecao] then
        begin
          BitBtn1.Visible:=false;
          BitBtn3.Visible:=true;
          ListBox1.Enabled:=false;
          StatusBar1.Panels.Items[0].Text:='Trabalhando -......';
          Timer1.Enabled:=true;
          Memo1.Lines.Add(traduz('download_de') + ' ' + ListBox1.Items.Strings[colecao] + ' ' +traduz('iniciado') + '...');
          posicao:=0;
          StatusBar1.Panels[1].Text:=traduz('baixando')+' '+ListBox1.Items.Strings[colecao]+'('+inttostr(posicao)+' '+traduz('de')+' '+quantidade_cartas[sets.readinteger('sets', 'total', 0)-colecao]+')';
          porcentagem_titulo(self);
          posicao := 1;
          abre_carta(self);
          break;
        end;
      end;
    end;
  end;
end;

procedure TForm1.WebBrowser1DocumentComplete(Sender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
begin
  salva_imagem(self);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  Memo1.Clear;
  repetidas := 0;
  colecao := 0;
  Label1.Caption:=cfg.ReadString('system', 'diretory', 'C:\Program Files\Magic Workstation\Pics');
  carrega_linguagem(self);
  Timer2.Enabled:=true;
end;

procedure TForm1.Label1Click(Sender: TObject);
begin
  Form2.Showmodal;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i,a,cont: integer;
  temp: string;
begin
  cfg := TIniFile.Create(ExtractFilePath(Application.ExeName)+'/config/config.ini');
  sets := TIniFile.Create(ExtractFilePath(Application.ExeName)+'/config/sets.ini');
  language:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'lang\'+ cfg.ReadString('system', 'language', 'pt-br') +'.lng');
  ListBox1.Clear;
  for i:=sets.ReadInteger('sets', 'total', 0) downto 1 do
  begin
    cont:=0;
    sigla[i]:='';
    nome_colecao[i]:='';
    sigla_mws[i]:='';
    quantidade_cartas[i]:='';
    temp:=sets.ReadString('sets', inttostr(i), '1');
    for a:=0 to length(temp) do
    begin
      if temp[a] <> '|' then
      begin
        if cont = 1 then
          sigla[i]:=sigla[i]+temp[a]
        else if cont = 2 then
          nome_colecao[i]:=nome_colecao[i]+temp[a]
        else if cont = 3 then
          sigla_mws[i]:=sigla_mws[i]+temp[a]
        else if cont = 4 then
          quantidade_cartas[i]:=quantidade_cartas[i]+temp[a];
      end
      else
        cont:=cont+1;
    end;
    ListBox1.Items.Add(nome_colecao[i]);
  end;
  Application.HintPause:=100;
  Application.HintHidePause:=10000;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  trabalhando:string;
begin
  trabalhando:=traduz('trabalhando');
  if StatusBar1.Panels.Items[0].Text = trabalhando+' -......' then
    StatusBar1.Panels.Items[0].Text := trabalhando+' .-.....'
  else if StatusBar1.Panels.Items[0].Text = trabalhando+' .-.....' then
    StatusBar1.Panels.Items[0].Text := trabalhando+' ..-....'
  else if StatusBar1.Panels.Items[0].Text = trabalhando+' ..-....' then
    StatusBar1.Panels.Items[0].Text := trabalhando+' ...-...'
  else if StatusBar1.Panels.Items[0].Text = trabalhando+' ...-...' then
    StatusBar1.Panels.Items[0].Text := trabalhando+' ....-..'
  else if StatusBar1.Panels.Items[0].Text = trabalhando+' ....-..' then
    StatusBar1.Panels.Items[0].Text := trabalhando+' .....-.'
  else if StatusBar1.Panels.Items[0].Text = trabalhando+' .....-.' then
    StatusBar1.Panels.Items[0].Text := trabalhando+' ......-'
  else if StatusBar1.Panels.Items[0].Text = trabalhando+' ......-' then
    StatusBar1.Panels.Items[0].Text := trabalhando+' -......'
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  colecao := 0;
  posicao:=0;
  contador_geral:=0;
  baixadas_colecao:=0;
  if DirectoryExists(cfg.ReadString('system', 'diretory', 'c:\program files\magic workstation\pics')) then
  begin
    if ListBox1.SelCount > 0 then
    begin
      if Application.MessageBox(PChar(traduz('pics_serao_removidas')), PChar(traduz('atencao')), MB_YESNO+MB_ICONQUESTION+MB_DEFBUTTON1)=mrYes then
      begin
        BitBtn1.Visible:=false;
        BitBtn3.Visible:=true;
        ListBox1.Enabled:=false;
        for colecao:=colecao to ListBox1.Count-1 do
        begin
          if ListBox1.Selected[colecao] then
          begin
            StatusBar1.Panels.Items[0].Text:=traduz('trabalhando') + ' -......';
            Timer1.Enabled:=true;
            Memo1.Lines.Add(traduz('download_de') + ' ' + ListBox1.Items.Strings[colecao] + ' ' + traduz('iniciado') + '...');
            StatusBar1.Panels[1].Text:=traduz('baixando')+' '+ListBox1.Items.Strings[colecao]+'('+inttostr(posicao)+' '+traduz('de')+' '+quantidade_cartas[sets.ReadInteger('sets', 'total', 0)-colecao]+')';
            porcentagem_titulo(self);
            posicao := 1;
            abre_carta(self);
            break;
          end;
        end;
      end;
    end;
  end
  else
  begin
    Application.MessageBox(PChar(traduz('diretorio_pics_invalido')), PChar(traduz('atencao')), MB_OK+MB_ICONERROR);
  end;

end;

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Form3.showmodal;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  Timer1.Enabled:=false;
  StatusBar1.Panels.Items[0].Text:='';
  repetidas:=0;
  ultima_carta:='';
  colecao:=ListBox1.Count-1;
  posicao:=9999;
  BitBtn3.Visible:=false;
  BitBtn1.Visible:=true;
  ListBox1.Enabled:=true;
  Memo1.Lines.Add(traduz('parado'));
  porcentagem_titulo(self);
  StatusBar1.Panels[1].Text:=traduz('parado');
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
var
  pt: TPoint;
begin
  GetCursorPos(Pt);
  PopupMenu1.Popup(pt.X, pt.Y);
end;

procedure TForm1.English1Click(Sender: TObject);
begin
  cfg.WriteString('system', 'language', 'en');
  language:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'lang\'+ cfg.ReadString('system', 'language', 'pt-br') +'.lng');
  carrega_linguagem(self);
end;

procedure TForm1.Portugus1Click(Sender: TObject);
begin
  cfg.WriteString('system', 'language', 'pt-br');
  language:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'lang\'+ cfg.ReadString('system', 'language', 'pt-br') +'.lng');
  carrega_linguagem(self);
end;

procedure TForm1.ListBox1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  i:integer;
begin
  if (Key = Ord('A')) and (ssCtrl in Shift) then
  begin
    for i:=0 to ListBox1.Count-1 do
      ListBox1.Selected[i]:=true;
    Key := 0;
  end;
end;

procedure TForm1.ListBox1DrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
begin
  if odSelected in State then
  begin
    ListBox1.Canvas.Brush.Color := clHighlight;
    ListBox1.Canvas.Font.Color := clHighlightText;
  end else
  begin
    ListBox1.Canvas.Font.Color := clBlack;
    if Odd(Index) then
      ListBox1.Canvas.Brush.Color := $00FFF8F0
    else
      ListBox1.Canvas.Brush.Color := clWindow;
  end;
  ListBox1.Canvas.TextRect(Rect, Rect.Left + 2, Rect.Top + 0, ListBox1.Items[Index]);
end;

procedure TForm1.Image2MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Image2.Left:=1;
  Image2.Top:=0;
end;

procedure TForm1.Image2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Image2.Left:=2;
  Image2.Top:=1;
end;

procedure TForm1.Image2Click(Sender: TObject);
begin
  Application.MessageBox(PChar(traduz('dica_usar_lista')), PChar(traduz('atencao')), MB_OK+MB_ICONINFORMATION);
end;

procedure TForm1.Timer2Timer(Sender: TObject);
var
  myfile: TFileStream;
  update: TIniFile;
begin
  try
    Timer2.Enabled:=false;
    myfile := TFileStream.Create(ExtractFileDir(Application.ExeName)+'\config\update.ini', fmCreate);
    IdHTTP1.Get('http://hadoukenteam.ueuo.com/mws_pics_downloader/update.ini', myfile);
  finally
    myfile.Free;
    update:=TIniFile.Create(ExtractFileDir(Application.ExeName)+'\config\update.ini');
    if update.ReadInteger('update', 'version', 0) > sets.ReadInteger('sets', 'version', 0) then
    begin
      SpeedButton2.Visible:=true;
      SpeedButton3.Visible:=true;
      Timer3.Enabled:=true;
    end;
  end;
  Timer2.Enabled:=false;
end;

procedure TForm1.SpeedButton2Click(Sender: TObject);
var
  myfile: TFileStream;
  erro: boolean;
begin
  try
    myfile := TFileStream.Create(ExtractFileDir(Application.ExeName)+'\config\sets.ini', fmCreate);
    IdHTTP2.Get('http://hadoukenteam.ueuo.com/mws_pics_downloader/sets.ini', myfile);
  finally
    Application.MessageBox(PChar(traduz('atualizacao_concluida')), PChar(traduz('atencao')), MB_OK+MB_ICONINFORMATION);
    Timer3.Enabled:=false;
    SpeedButton2.Visible:=false;
    SpeedButton3.Visible:=false;
    erro:=false;
  end;
  if erro <> false then
  begin
    speedbutton2.Visible:=true;
    SpeedButton3.Visible:=true;
    Application.MessageBox(PChar(traduz('falha_atualizacao')), PChar(traduz('atencao')), MB_OK+MB_ICONERROR);
  end;
end;

procedure TForm1.Timer3Timer(Sender: TObject);
begin
  if SpeedButton2.Visible=true then
    speedbutton2.Visible:=false
  else
    speedbutton2.Visible:=true;
end;

procedure TForm1.SpeedButton3Click(Sender: TObject);
begin
  SpeedButton2.Click;
end;

end.
