#!/bin/sh

{

sed  '/INCLUDE_START/,$d' edit.html

echo -n '<link rel="icon" type="image/x-icon" href="data:image/x-icon;base64,' ; base64 favicon.ico|tr -d '\n' ; echo '">'
echo -n '<style type="text/css" title="original">' ; cat css/style.min.css | tr -d '\n' ; echo '</style>'
echo -n '<style type="text/css" title="github">' ; cat css/github.min.css | tr -d '\n' ; echo '</style>'
echo -n '<style type="text/css" title="gitlab">' ; cat css/gitlab.min.css | tr -d '\n' ; echo '</style>'

echo -n '<script type="text/javascript">' ; cat js/base64.min.js | tr -d '\n' ; echo '</script>'
echo -n '<script type="text/javascript">' ; cat js/crc32.min.js | tr -d '\n' ; echo '</script>'
echo -n '<script type="text/javascript">' ; cat js/vue.min.js | tr -d '\n' ; echo '</script>'
echo -n '<script type="text/javascript">' ; cat js/marked.min.js | tr -d '\n' ; echo '</script>'
echo -n '<script type="text/javascript">' ; cat js/sweetalert2.all.min.js | tr -d '\n' ; echo '</script>'
echo -n '<script type="text/javascript">' ; cat js/lodash.min.js | tr -d '\n' ; echo '</script>'
echo -n '<script type="text/javascript">' ; cat js/com.js ; echo '</script>'
echo -n '<script type="text/javascript">' ; cat js/sjcl.js ; echo '</script>'

sed  '1,/INCLUDE_END/d' edit.html

} > index.html

{
echo '<?php'

echo '/* Markdown Editor Installer */' ;
echo -n '$index="' ; base64 index.html|tr -d '\n' ; echo '";' ;
echo -n '$htaccess="' ; base64 .htaccess|tr -d '\n' ; echo '";' ;
echo -n '$edit="' ; base64 edit.php|tr -d '\n' ; echo '";' ;
echo -n '$fav="' ; base64 favicon.ico|tr -d '\n' ; echo '";' ;
echo
echo 'if( !file_exists(".htaccess") ) { file_put_contents( ".htaccess", base64_decode($htaccess) ) ; }'
echo 'if( !file_exists("favicon.ico") ) { file_put_contents( "favicon.ico", base64_decode($fav) ) ; }'
echo 'if( !file_exists("index.html") ) { file_put_contents( "index.html", base64_decode($index) ) ; }'
echo 'if( !file_exists("pass") ) { mkdir("pass") ; }'
echo 'if( !file_exists("pass/.htaccess") ) { file_put_contents( "pass/.htaccess", "deny from all" ) ; }'
echo 'header("Location: index.html");'

echo '?>'
} > install.php