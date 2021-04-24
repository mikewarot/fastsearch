program fastsearch_demo;
const
  Pattern = 'EXAMPLE';
  SourceText = 'HERE IS A SIMPLE EXAMPLE';
var
  s : string;
  bitmask    : array[0..255] of uInt64;
  StartBit      : uInt64;
  s_len      : uInt64;
  firstmatch : uInt64;
  target     : string;

  procedure setmask(searchstring : string);
  var
    i     : integer;
    bit   : uInt64;
    c : char;
  begin
    for i := 0 to 255 do
      bitmask[i] := 0;
    if length(searchstring) > 64 then
      begin
        Writeln('Search string was too long, halting');
        exit;
      end;

    bit := 1;
    for i := 1 to (64-length(searchstring)) do
      bit := bit shl 1;
    StartBit := bit;
    s_len := length(searchstring);

    for i := 1 to length(searchstring) do
      begin
        c := searchstring[i];
        bitmask[ord(c)] := bitmask[ord(c)] or bit;
        bit := bit shl 1;
      end;
  end;

  procedure do_fast_search(var TargetString : string);
  var
    T_Len : uInt64;
    T_Start : Pointer;
  begin
    firstmatch := 0;
    T_len := length(TargetString);
    if (T_len = 0) then exit;
    T_Start := @TargetString[1];
    {$asmmode Intel}
    asm
      xor   rax,rax                   // clear the whole register
      xor   rbx,rbx                   // clear the register
      mov   rsi,T_Start               // point rsi at the target string
      lea   rdi,[rip+BitMask]         // point dsi at the mask table
      mov   rcx,qword T_len                 // count of characters into rcx
      xor   rdx,rdx                   // flags go here
      mov   r11,[rip+StartBit]

      cld                             // we go UP the string, not down
    @@test_character:
      xor   rax,rax
      lodsb                           // get the character and move it into bl
      mov   rbx,rax
      shl   rbx,3                     //  rbx=rbx*8
      or    rdx,r11
      and   rdx,[RDI+RBX]             // lookup BitMask[rbx]
      shl   rdx,1
      jc    @@got_a_hit
      loop  @@test_character
      jmp   @@not_found

    @@got_a_hit:
      mov   rax,qword T_len
      sub   rax,rcx
      sub   rax,qword [rip+s_len]
      add   rax,2                     // index 1, plus we hadn't decremented RCX yet
      mov   qword [firstmatch],rax

    @@not_found :


    end;

  end;

var
  i : integer;
begin
  s := Pattern;
  setmask(s);

  target := SourceText;

  writeln('Target text is ',length(target),' characters long');

  writeln('Start bit = ',HexStr(StartBit,16));

  for i := 0 to 255 do
    if bitmask[i] <> 0 then
      writeln(hexstr(i,2),' ',hexstr(bitmask[i],16));

  do_fast_search(target);

  writeln('Found at ',firstmatch);
end.

