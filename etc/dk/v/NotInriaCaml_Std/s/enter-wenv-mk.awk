{ 
    gsub(/@WINEPREFIX@/, WINEPREFIX);
    gsub(/@WINEHOME@/, WINEHOME);
    print $0 > OUTPUT_FILE;
}