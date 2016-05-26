module mladen


contains 

subroutine writetoscreen(message)
    use hydro_parameters, only: rank
    implicit none
    character(len=*), intent(in), optional :: message
    
    if(rank==0) then
        if(present(message)) then
            if (len(message) /= 0) then
                write(6, '(A)') message
            end if
        else
            write(6, '(A)') "You left no specific message."
        end if

    end if
end subroutine writetoscreen


subroutine makedir(dirname)
!create a directory.
    use hydro_parameters, only: rank
    implicit none
    character(len=*), intent(in) :: dirname
    character(30) :: cmnd

    if (rank==0) then

        cmnd = 'mkdir -p '//TRIM(dirname)
        call system(cmnd)
        call writetoscreen(' Created output directory '//TRIM(dirname))

    end if
end subroutine makedir




end module mladen
