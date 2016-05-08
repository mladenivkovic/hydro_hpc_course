module mladen


contains 

subroutine writetoscreen(message)
    implicit none
    character(len=*), intent(in), optional :: message

    write(6, '(A)') 
    write(6, '(A)') "########################################"
    write(6, '(A)') 
    write(6, '(A)') "This is a message for Mladen."
   
    if(present(message)) then
        if (len(message) /= 0) then
            write(6, '(A)')
            write(6, '(A)') "Your message is: "
            write(6, '(A)') message
        end if
    else
        write(6, '(A)') "You left no specific message."
    end if

    write(6, '(A)') 
    write(6, '(A)') "########################################"
    write(6, '(A)') 

end subroutine writetoscreen


end module mladen
