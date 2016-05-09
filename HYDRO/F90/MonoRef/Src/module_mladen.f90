module mladen


contains 

subroutine writetoscreen(message)
    ! will be modified for myid=1 ...
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


subroutine makedir(dirname)
!create a directory.
    implicit none
    character(len=*), intent(in) :: dirname
    character(30) :: cmnd

    cmnd = 'mkdir -p '//TRIM(dirname)
    call system(cmnd)
    
    call writetoscreen('created directory '//TRIM(dirname))
end subroutine makedir




end module mladen
