with Ada.Text_IO; use Ada.Text_IO;
with Bar;

procedure Main is
   Amount : constant := $Amount;
begin
   Bar.Do_Things;

   #if Foo = "foo" then
      Put_Line ("Have Foo");
   #else
      Put_Line ("Do not have Foo");
   #end if;

   Put_Line ("Amount = " & Amount'Image);
end Main;
