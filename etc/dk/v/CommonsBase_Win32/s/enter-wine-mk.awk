{ 
    gsub(/@GNUTLS_LIB@/, GNUTLS_LIB);
    print $0 > OUTPUT_FILE;
}