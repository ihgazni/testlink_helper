source /usr/local/bin/DLIB/nv.tcl
source /usr/local/bin/DLIB/line.tcl
source /usr/local/bin/DLIB/file.tcl
source /usr/local/bin/DLIB/color.tcl
source /usr/local/bin/DLIB/aaa.tcl
# source /usr/local/bin/DLIB/tools.tcl
source /usr/local/bin/DLIB/win.tcl
source /usr/local/bin/DLIB/rand.tcl
source /usr/local/bin/DLIB/web.tcl
source /usr/local/bin/DLIB/html_parser.tcl
package require json
# set opts(-timeout_wget_real) 120 
# --post-data '$post_body'

# wget --timeout=$opts(-timeout_wget_real) --tries=10 --secure-protocol=TLSv1 --no-check-certificate -t 1 -a ./cp.log -O ./cp2.log  '$url_1'
# wget --timeout=120 --tries=10 --secure-protocol=TLSv1 --no-check-certificate -t 1 -a ./cp.log -O ./cp2.log  http://testlink/testlink1.9/index.php
#curl 要把多个link写在一行 或者一个file -K 里面keepalive才生效
# curl -v http://testlink/testlink1.9/index.php http://testlink/testlink1.9/index.php

# -uname
# set uname [lindex $argv 1]
# -passwd

proc gen_ck_list { id_list leaf_list prepend} {
    global global_list
    set ilen [llength $id_list]
    set llen [llength $leaf_list]
    set nl {}
    set nnl {}
    for {set i 0} {$i < $ilen} { incr i } {
        if { [ regexp -nocase false [lindex $leaf_list $i]] } {
            lappend nl [lindex $id_list $i]
        } else {
            lappend nnl [lindex $id_list $i]
        }
    }
    set gl [list_ele_prepend  $nnl $prepend]
    set ul [list_ele_prepend  $nl $prepend]
    set global_list [concat $global_list $gl]
    return $ul
} 

proc testlink_time_to_seconds { tltime } {
    #26/05/2015 01:02:33
    set seconds [clock scan $tltime -format {%d/%m/%Y %H:%M:%S}]
    return $seconds 
}

proc seconds_to_testlink_time { seconds } {
    #1432573353
    set realtime [clock format $seconds -format {%d/%m/%Y %H:%M:%S}]
    return $realtime 
}

proc seconds_to_suffix_time { seconds } {
    #1432573353
    set realtime [clock format $seconds -format {%d_%m_%Y_%H:%M:%S}]
    return $realtime 
}




array set opts {
    -uname ""
    -passwd ""
    -creater ""
    -midifier ""
    -filter    ""
    -cr_start_time ""
    -cr_end_time ""
    -md_start_time ""
    -md_end_time ""
    -local_file ""
}

array set opts $argv

if { ![string equal "" $opts(-local_file)] } {
    set local_file $opts(-local_file)
    set text_temp [get_content $local_file]
    set text_temp [string trim $text_temp]
    set info_list [split $text_temp \n]
    set fn $opts(-local_file)
} else {
    set uname $opts(-uname)
    set passwd $opts(-passwd)
    
    
    # set uname dli
    # set passwd 1qaz2wsX
    
    #step 1
    set url_1 http://testlink/testlink1.9/index.php
    set req_headers [nv::gen_req_headers]
    set req_headers [nv::patch_non_zlib $req_headers]
    set resp [nv::req $url_1 -headers $req_headers -keepalive 0]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    #step 2
    regexp {location.href='(.*)'} $resp_arr(data) o url_2
    set req_cookie [nv::gen_cookie_from_resp $resp_arr(meta)]
    set req_headers [nv::gen_req_headers Referer $url_1 Cookie $req_cookie ]
    set req_headers [nv::patch_non_zlib $req_headers]
    set resp [nv::req $url_2 -headers $req_headers -keepalive 0]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    #step 3
    set base [ nv::get_base $resp_arr(data) ]
    array unset arr_form
    array set arr_form [lindex [nv::extract_form_input  $resp_arr(data)] 0]
    set req_body [nv::uri_escape $arr_form(query)] 
    set req_body [regsub {tl_login=} $req_body "tl_login=$uname"]
    set req_body [regsub {tl_password=} $req_body "tl_password=$passwd"]
    set url_3 $base
    append url_3 $arr_form(action_url)
    set req_headers [nv::remove_header_from_req_headers $req_headers Referer]
    set req_headers [nv::add_header_to_req_headers $req_headers Referer $url_2]
    set req_headers [nv::add_header_to_req_headers $req_headers Origin "http://testlink"]
    set resp [nv::req $url_3 -headers $req_headers -keepalive 0 -method [string toupper $arr_form(method)] -post_body $req_body]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    #step 4
    regexp {location.href='(.*)'} $resp_arr(data) o url_4
    set req_headers [nv::remove_header_from_req_headers $req_headers Origin]
    set req_headers [nv::remove_header_from_req_headers $req_headers Referer]
    set req_headers [nv::add_header_to_req_headers $req_headers Referer $url_3]
    set resp [nv::req $url_4 -headers $req_headers -keepalive 0]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    
    #step 5
    array unset arr_srcs
    array set arr_srcs [lindex [nv::extract_frameset_frame $resp_arr(data)] 0]
    set url_5 [relative_url_to_full_url -base $url_4 -rel [lindex $arr_srcs(frame_srcs) 0]]
    set url_6 [relative_url_to_full_url -base $url_4 -rel [lindex $arr_srcs(frame_srcs) 1]]
    
    set req_headers [nv::remove_header_from_req_headers $req_headers Referer]
    set req_headers [nv::add_header_to_req_headers $req_headers Referer $url_4]
    set resp [nv::req $url_5 -headers $req_headers -keepalive 0]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    
    set base [ nv::get_base $resp_arr(data) ]
    array unset form_select
    array set form_select [lindex [nv::extract_form_select $resp_arr(data)] 0]
    array unset query_num 
    array set query_num $form_select(query)
    set url_7 $url_5
    append url_7 /?
    append url_7 $form_select(name)
    append url_7 =
    append url_7 $query_num(Instant)
    
    #step 6
    set req_headers [nv::remove_header_from_req_headers $req_headers Referer]
    set req_headers [nv::add_header_to_req_headers $req_headers Referer $url_4]
    set resp [nv::req $url_6 -headers $req_headers -keepalive 0]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    
    array unset arr_rh
    array set arr_rh $req_headers
    set req_cookie $arr_rh(Cookie)
    append req_cookie "; "
    append req_cookie [nv::gen_cookie_from_resp $resp_arr(meta)]
    set req_cookie [string trim $req_cookie]
    set req_cookie [string trim $req_cookie ";"]
    set req_headers [array_values_replace -arr_list $req_headers -key Cookie -value $req_cookie]
    
    #step 7
    set req_headers [nv::remove_header_from_req_headers $req_headers Referer]
    set req_headers [nv::add_header_to_req_headers $req_headers Referer $url_5]
    set resp [nv::req $url_7 -headers $req_headers -keepalive 0]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    #step 8
    array unset arr_rh
    array set arr_rh $req_headers
    set req_cookie $arr_rh(Cookie)
    append req_cookie "; "
    set new_req_cookie [lindex [nv::gen_cookie_from_resp $resp_arr(meta)] 0]
    set req_cookie [nv::update_cookie $req_cookie $new_req_cookie]
    set req_cookie [string trim $req_cookie]
    set req_cookie [string trim $req_cookie ";"]
    set req_headers [array_values_replace -arr_list $req_headers -key Cookie -value $req_cookie]
    set req_headers [nv::remove_header_from_req_headers $req_headers Referer]
    set req_headers [nv::add_header_to_req_headers $req_headers Referer $url_7]
    
    
    regexp {parent.mainframe.location = "(.*)";} $resp_arr(data) o url_8
    set resp [nv::req $url_8 -headers $req_headers -keepalive 0]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    
    # step 9
    array unset arr_rh
    array set arr_rh $req_headers
    set req_cookie $arr_rh(Cookie)
    append req_cookie "; "
    set new_req_cookie [lindex [nv::gen_cookie_from_resp $resp_arr(meta)] 0]
    set req_cookie [nv::update_cookie $req_cookie $new_req_cookie]
    set req_cookie [string trim $req_cookie]
    set req_cookie [string trim $req_cookie ";"]
    set req_headers [array_values_replace -arr_list $req_headers -key Cookie -value $req_cookie]
    
    set url_9 http://testlink/testlink1.9/lib/general/frmWorkArea.php?feature=editTc
    
    set resp [nv::req $url_9 -headers $req_headers -keepalive 0]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    # step 10
    array unset arr_srcs
    array set arr_srcs [lindex [nv::extract_frameset_frame $resp_arr(data)] 0]
    set base [ nv::get_base $resp_arr(data) ]
    set url_10 [relative_url_to_full_url -base $base -rel [lindex $arr_srcs(frame_srcs) 0]]
    set url_11 [relative_url_to_full_url -base $base -rel [lindex $arr_srcs(frame_srcs) 1]]
    
    set req_headers [nv::remove_header_from_req_headers $req_headers Referer]
    set req_headers [nv::add_header_to_req_headers $req_headers Referer $url_9]
    
    set resp [nv::req $url_10 -headers $req_headers -keepalive 0]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    regexp {form_token=[0-9]+} $resp_arr(data) form_token
    
    regexp {treeCfg.loader=([^\n]+)} $resp_arr(data) o treeCfg.loader
    set treeCfg.loader [string trim ${treeCfg.loader}]
    set treeCfg.loader [string trim ${treeCfg.loader} ";"]
    set treeCfg.loader [string trim ${treeCfg.loader}]
    set treeCfg.loader [string range ${treeCfg.loader} 1 end-1]
    
    
    regexp {treeCfg.cookiePrefix=([^\n]+)} $resp_arr(data) o treeCfg.cookiePrefix
    set treeCfg.cookiePrefix [string trim ${treeCfg.cookiePrefix}]
    set treeCfg.cookiePrefix [string trim ${treeCfg.cookiePrefix} ";"]
    set treeCfg.cookiePrefix [string trim ${treeCfg.cookiePrefix} ]
    set treeCfg.cookiePrefix [string range ${treeCfg.cookiePrefix} 1 end-1]
    
    #/testlink1.9/third_party/ext-js/ext-all.js
    # Ext.Component.AUTO_ID = 1000;
    # document.cookie = "ys-" + a + "=" + this.encodeValue(b)
    #document.cookie = "ys-" + a + "=" + this.encodeValue(b)
    #ys-tproject_99267_ext-comp-1001=a%3As%253A/99267
    #this.id = "ext-comp-" + (++Ext.Component.AUTO_ID)
    #Ext.state.Provider = Ext.extend(Ext.util.Observable, 
    #
    
    #step 11
    set resp [nv::req $url_11 -headers $req_headers -keepalive 0]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    
    #step 12
    set url_12 ${treeCfg.loader}
    set temp "ys-"
    append temp ${treeCfg.cookiePrefix}
    append temp "ext-comp-"
    append temp 1001
    append temp "=a%3As%253A/$query_num(Instant)"
    append req_cookie "; "
    append req_cookie $temp
    set req_headers [nv::remove_header_from_req_headers $req_headers Cookie]
    set req_headers [nv::add_header_to_req_headers $req_headers Cookie $req_cookie]
    set req_headers [nv::remove_header_from_req_headers $req_headers Referer]
    set req_headers [nv::add_header_to_req_headers $req_headers Referer $url_10]
    
    set resp [nv::req $url_12 -headers $req_headers -keepalive 0]
    array unset resp_arr
    array set resp_arr $resp
    parray resp_arr
    ::http::reset $resp_arr(tok)
    ::http::cleanup $resp_arr(tok)
    
    
    
    regexp {\[(.*)\]} $resp_arr(data) o temp
    set lines [regexp -all -inline {\{.*?\}} $temp]
    set llen [llength $lines]
    set sons {}
    for {set i 0} { $i < $llen } { incr i } {
         set line [lindex $lines $i]
         set el [json::json2dict $line]
         lappend sons $el
    }
    
    

    
    
    
    
    
    
    
    set temp "ys-"
    append temp ${treeCfg.cookiePrefix}
    append temp "ext-comp-"
    append temp 1001
    append temp "=a%3As%253A/$query_num(Instant)"
    set prepend $temp
    append prepend "/"
    
    set global_list {}
    set id_list [get_subvaluelist_from_parentlist $sons id]
    set leaf_list [get_subvaluelist_from_parentlist $sons leaf]
    set ck_list [gen_ck_list $id_list $leaf_list $prepend]
    
    set global_list {}
    while { [llength $ck_list ] > 0  } {
        set ulen [llength $ck_list]
        set temp_id_list {}
        set temp_leaf_list {}
        set temp_ck_list {}
        
        
        for { set i 0 } { $i < $ulen } { incr i } {
            set each_id_list {}
            set each_leaf_list {}
            set each_ck_list {}
            set ck [lindex $ck_list $i]
            regexp {.*/([0-9]+)} $ck o node
            set req_body "node=$node"
            array unset arr_rh
            array set arr_rh $req_headers
            set req_cookie $arr_rh(Cookie)
            append req_cookie "; "
            set new_req_cookie $ck
            set req_cookie [nv::update_cookie $req_cookie $new_req_cookie]
            set req_cookie [string trim $req_cookie]
            set req_cookie [string trim $req_cookie ";"]
            set req_headers [array_values_replace -arr_list $req_headers -key Cookie -value $req_cookie]
            puts "req_headers: $req_headers"
            puts "req_body: $req_body"
            puts "i:$i"
            set resp [nv::req $url_12 -headers $req_headers -keepalive 0 -method [string toupper "post"] -post_body $req_body]
            array unset resp_arr
            array set resp_arr $resp
            parray resp_arr
            ::http::reset $resp_arr(tok)
            ::http::cleanup $resp_arr(tok)
            regexp {\[(.*)\]} $resp_arr(data) o temp
            set temp [string trim $temp "\{"]
            set temp [string trim $temp "\}"]
            set temp [regsub -all {\},\{} $temp \x01]
            set lines [split $temp \x01]
            set llen [llength $lines]
            set sons {}
            for {set j 0} { $j < $llen } { incr j } {
                 set line "\{"
                 append line [lindex $lines $j]
                 append line "\}"
                 set el [json::json2dict $line]
                 lappend sons $el
            }
            set prepend $ck
            append prepend "/"
            set each_id_list [get_subvaluelist_from_parentlist $sons id]
            set each_leaf_list [get_subvaluelist_from_parentlist $sons leaf]
            set each_ck_list [gen_ck_list $each_id_list $each_leaf_list $prepend]
            set temp_id_list [concat $temp_id_list $each_id_list]
            set temp_leaf_list [concat $temp_leaf_list $each_leaf_list]
            set temp_ck_list [concat $temp_ck_list $each_ck_list]
            #sleep 5
            
        }
        set ck_list $temp_ck_list
        
    
    }
    
    
    set all_leaf_list $global_list 
    set llen [llength $all_leaf_list]
    

    
    set info_list {}
    
    for { set i 0} { $i < $llen } { incr i } {
        set leaf [lindex $all_leaf_list $i]
        array unset arr_rh
        array set arr_rh $req_headers
        set req_cookie $arr_rh(Cookie)
        append req_cookie "; "
        set new_req_cookie $leaf
        regexp {(.*)/([0-9]+)} $new_req_cookie o new_req_cookie id
        set req_cookie [nv::update_cookie $req_cookie $new_req_cookie]
        set req_cookie [string trim $req_cookie]
        set req_cookie [string trim $req_cookie ";"]
        set req_headers [array_values_replace -arr_list $req_headers -key Cookie -value $req_cookie]
        set url http://testlink/testlink1.9/lib/testcases/archiveData.php?version_id=undefined&edit=testcase&id=$id&$form_token
        set resp [nv::req $url -headers $req_headers -keepalive 0]
        array unset resp_arr
        array set resp_arr $resp
        parray resp_arr
        ::http::reset $resp_arr(tok)
        ::http::cleanup $resp_arr(tok)
        
        
        #initial
        set RN ""
        set TITLE ""
        set CRTIME ""
        set CRER ""
        set LMTIME ""
        set LMER  
        #initial
        
        
        
        
        
        regexp {(RN-[0-9]+):(.*?)</h2>} $resp_arr(data) o RN TITLE
        regexp {(.*?)</h2>} $TITLE o TITLE
        #this is for a tclsh regexp no-greed mode strange issue
        regexp {Created on&nbsp;(.*?)&nbsp;[\n\r\t ]+by&nbsp;(.*?)\n} $resp_arr(data) o CRTIME CRER
        regexp {Last modified on &nbsp;(.*?)[\n\r\t ]+&nbsp;by&nbsp;(.*?)\n} $resp_arr(data) o LMTIME LMER
        set mini_info {}
        lappend mini_info RN
        lappend mini_info $RN
        lappend mini_info TITLE
        lappend mini_info $TITLE
        lappend mini_info CRTIME
        lappend mini_info $CRTIME
        lappend mini_info CRER
        lappend mini_info $CRER
        lappend mini_info LMTIME
        if { [info exist LMTIME] } {
            lappend mini_info $LMTIME
        } else {
            lappend mini_info ""
        }
        lappend mini_info LMER
        if { [info exist LMER] } {
            lappend mini_info $LMER
        } else {
            lappend mini_info ""
        }
        lappend info_list $mini_info
    }
    
    

    
    set RN_info_suffix [seconds_to_suffix_time [clock seconds]]
    
    set fn "/usr/local/bin/TESTLINK_TOOLS"
    append fn "/RNinfo__$RN_info_suffix"
    
    
    set text_info_list ""
    
    for {set i 0} {$i < [llength $info_list]} { incr i } {
        set line [lindex $info_list $i]
        set title [lindex $line 3]
        regexp {(.*?)</h2>} $title o title
        set line [lreplace $line 3 3 $title]
        set line [regsub -all {\n} $line " "]
        append text_info_list $line
        append text_info_list \n
    }
    
    set text_info_list [string trim $text_info_list]
    
    
    write_content $text_info_list $fn
}
# ######################################### #

# #############################/usr/local/bin/TESTLINK_TOOLS/RNinfo__20_06_2015_08:31:38############ #

set rn_l [get_subvaluelist_from_parentlist $info_list RN]
set tt_l [get_subvaluelist_from_parentlist $info_list TITLE]
set crer_l [get_subvaluelist_from_parentlist $info_list CRER]
set crtm_l [get_subvaluelist_from_parentlist $info_list CRTIME]
set mder_l [get_subvaluelist_from_parentlist $info_list LMER]
set mdtm_l [get_subvaluelist_from_parentlist $info_list LMTIME]


# ######################################### #
set llen [llength $rn_l]
for {set i 0} { $i < $llen } { incr i} {
    if { [string equal "" [lindex $mder_l  $i] ] } {
        set mder_l [lreplace $mder_l $i $i [lindex $crer_l $i]]
    }
    if { [string equal "" [lindex $mdtm_l  $i] ] } {
        set mdtm_l [lreplace $mdtm_l $i $i [lindex $crtm_l $i]]
    }
}

# ######################################### #

set llen [llength $rn_l]
if { [string equal $opts(-creater) ""] } {
} else {
    set il_1 {}
    for {set i 0} { $i < $llen } { incr i} {
        if { [ string equal $opts(-creater) [lindex $crer_l $i] ]} {
            lappend il_1 $i
        }
    }
}

set llen [llength $rn_l]
if { [string equal $opts(-midifier) ""] } {
} else {
    set il_2 {}
    for {set i 0} { $i < $llen } { incr i} {
        if { [ string equal $opts(-midifier) [lindex $mder_1 $i] ]} {
            lappend il_2 $i
        }
    }
}

set llen [llength $rn_l]
if { [string equal $opts(-cr_start_time) ""] } {
    set il_3 {}
    for {set i 0} { $i < $llen } { incr i} {
        lappend il_3 $i
    }
} else {
    set il_3 {}
    for {set i 0} { $i < $llen } { incr i} {
        set cr_start_time [testlink_time_to_seconds $opts(-cr_start_time)]
        set tm [testlink_time_to_seconds [lindex $crtm_l  $i] ]
        if { [ expr $tm >=  $cr_start_time ]} {
            lappend il_3 $i
        }
    }
}

set llen [llength $il_3]
if { [string equal $opts(-cr_end_time) ""] } {
    set il_4 {}
    for {set i 0} { $i < $llen } { incr i} {
        lappend il_4 [lindex $il_3 $i]
    }
} else {
    set il_4 {}
    for {set i 0} { $i < $llen } { incr i} {
        set cr_end_time [testlink_time_to_seconds $opts(-cr_end_time)]
        set tm [testlink_time_to_seconds [lindex $crtm_l  [lindex $il_3 $i] ] ]
        if { [ expr $tm <=  $cr_end_time ]} {
            lappend il_4 [lindex $il_3 $i]
        }
    }
}

set llen [llength $rn_l]
if { [string equal $opts(-md_start_time) ""] } {
    set il_5 {}
    for {set i 0} { $i < $llen } { incr i} {
        lappend il_5 $i
    }
} else {
    set il_5 {}
    for {set i 0} { $i < $llen } { incr i} {

        
       set mdtm [lindex $mdtm_l  $i]
        if { [string equal "" $mdtm ] } {
            set mdtm [expr [testlink_time_to_seconds $opts(-md_start_time)] - 1]
            set mdtm [seconds_to_testlink_time $mdtm]
        }
        set md_start_time [testlink_time_to_seconds $opts(-md_start_time)]
        set tm [testlink_time_to_seconds $mdtm]
        
        
        
        
        if { [ expr $tm >=  $md_start_time ]} {
            lappend il_5 $i
        }
    }
}

set llen [llength $il_5]
if { [string equal $opts(-md_end_time) ""] } {
    set il_6 {}
    for {set i 0} { $i < $llen } { incr i} {
        lappend il_6 [lindex $il_5 $i]
    }
} else {
    set il_6 {}
    for {set i 0} { $i < $llen } { incr i} {
        set md_end_time [testlink_time_to_seconds $opts(-md_end_time)]
        #set tm [testlink_time_to_seconds [lindex $mdtm_l  [lindex $il_5 $i]] ]
        
       set mdtm [lindex $mdtm_l  [lindex $il_5 $i]]
        if { [string equal "" $mdtm ] } {
            set mdtm [expr [testlink_time_to_seconds $opts(-md_end_time)] + 1]
            set mdtm [seconds_to_testlink_time $mdtm]
        }
        set md_start_time [testlink_time_to_seconds $opts(-md_end_time)]
        set tm [testlink_time_to_seconds $mdtm]
        
        if { [ expr $tm <=  $md_end_time ]} {
            lappend il_6 [lindex $il_5 $i]
        }
    }
}

# set llen [llength $il_6]
# set rslt {}
# for {set i 0} { $i < $llen } { incr i} {
    # lappend rslt [lindex $rn_l [lindex $il_6 $i] ]
    # lappend rslt [lindex $tt_l [lindex $il_6 $i] ]
# }

# array unset arr
# array set arr $rslt
# parray arr 

set il [list_intersec $il_4 $il_6]

set llen [llength $il]
regexp {(.*)/(.*)} $fn o dir rel
set new_fn "$dir/.${rel}__filtered_by_time"

set new_text ""

for {set i 0} { $i < $llen } { incr i} {
    append new_text [lindex $info_list [lindex $il $i]]
    append new_text \n
}
set new_text [string trim $new_text]

write_content $new_text $new_fn


# ############################# #
# set cond "egrep \"CRER dli|LMER dli\""
set cond $opts(-filter)
set cmd "cat $new_fn | $cond "
set rslt [exec {*}$cmd]
puts [paint_str $rslt green]
exec rm $new_fn
