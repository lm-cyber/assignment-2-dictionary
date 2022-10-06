%define dict_head 0

%macro colon 2
    %ifid %2
        %2:
        dq dict_head
    %else
        %error "Second parameter of colon should be an identifier"
    %endif
    %ifstr %1
        db %1, 0
    %else
        %error "First parameter of colon should be a string"
    %endif
    %define dict_head %2
%endmacro