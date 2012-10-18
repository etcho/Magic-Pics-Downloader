program MWS_Pics_Downloader;

uses
  Forms,
  UnitMain in 'UnitMain.pas' {Form1},
  UnitDirectory in 'UnitDirectory.pas' {Form2},
  UnitAbout in 'UnitAbout.pas' {Form3};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'MWS Pics Downloader';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
