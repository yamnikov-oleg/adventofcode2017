{$mode delphi}

program Day9;

uses Sysutils;

type
  ParserState = (Free, Garbage, Escaping);

var
  inputFile: TextFile;
  readChar: char;

  state: ParserState = Free;
  stackDepth: integer = 0;

  groupDepthsSum: integer = 0;
  canceledChars: integer = 0;

begin
  // Require input file path
  if ParamCount < 1 then
  begin
    Writeln('Requires input file path');
    Halt(1);
  end;

  // Open the file
  AssignFile(inputFile, ParamStr(1));

  try
    Reset(inputFile);
  except
    on e: EInOutError do
    begin
      Writeln('Error while opening the file: ', e.message);
      Halt(1);
    end;
  end;

  // Process the file char by char
  while not Eof(inputFile) do
  begin
    Read(inputFile, readChar);
    case state of
      // Groups parsing state
      Free:
        case readChar of
          '{':
            begin
              stackDepth += 1;
              groupDepthsSum += stackDepth;
            end;
          '}':
            stackDepth -= 1;
          '<':
            state := Garbage;
        end;
      // Garbage parsing state
      Garbage:
        case readChar of
          '>':
            state := Free;
          '!':
            state := Escaping;
        else
            canceledChars += 1;
        end;
      // Character escaping state
      Escaping:
        state := Garbage;
    end;
  end;

  Close(inputFile);

  Writeln('Sum of group depths: ', groupDepthsSum);
  Writeln('Canceled characters: ', canceledChars);
end.
