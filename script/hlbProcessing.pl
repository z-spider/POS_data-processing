#合利宝数据处理脚本
#真正需要修改的数据只有7行，
#$posnam，$T_keyname，$T_filepattern，$T_pattern，$A_keyname，$A_filepattern，$A_pattern

###加载模块、文件头和初始变量###
require "./script/Process.pm";#请求数据处理模块
open STDOUT,">>processing.log" or die "can not open processing.log, $!";
open STDERR,">>processing.log" or die "can not open processing.log, $!";
my $posname = 'HLB';#POS系统名缩写
my $time = localtime();#时间
print "$posname __________ $time __________ $posname\n";#日志文件抬头,一边10个_

###交易数据的处理###
my $T_keyname = Process::hand('交易');#数据文件类型标记，根据文件名而来，分为交易和激活两种类型
my $T_filepattern = "^.+?pos.*?($T_keyname).+?\\d+_(\\d{6})\\d+\\.xlsx\\.txt\$";#文件名pattern，用keyname过滤文件类型
my $T_pattern = '^\w+\t.*?\t.*?\t\w+\t(\S+)\t\S+\t\S+\t\S+\t\S+\t\S+\t\S+\t\S+\t([0-9,\.]+)\t';#文件内容pattern
#这两句话和bless不是很懂
$T_radeObject = new Process($posname,$T_filepattern,$T_pattern);#按顺序输入参数
#初始化这一步写的不好，或许可以优化，因为我完全没必要初始化两次（后面还有一次），可不初始化又执行不下去
my ( $order, $mapping ) = $T_radeObject->init();#执行数据初始化,返回ID映射和顺序数组
my ( $T_outfile, $all_trade) = $T_radeObject->TradeProcess($order, $mapping);#执行数据处理，返回输出文件(句柄)和数据结果

###激活数据的处理###
#my $posname = 'HLB';#POS系统名缩写
my $A_keyname = Process::hand('激活');
my $A_filepattern = "^.+?pos.*?($A_keyname).+?\\d+_(\\d{6})\\d+\\.xlsx\\.txt\$";
my $A_pattern = '^\d+\t.*?\t.*?\t\w+\t(\S+)\t';#文件内容pattern
$A_ctivateObject = new Process($posname,$A_filepattern,$A_pattern);#按顺序输入参数
#这里其实没必要存储$order, $mapping
my ( $order, $mapping ) = $A_ctivateObject->init();#执行数据初始化,返回ID映射和顺序数组
my ( $A_outfile, $all_activate) = $A_ctivateObject->ActivateProcess($order, $mapping);#执行数据处理，返回输出文件(句柄)和数据结果

###输出数据结果###
$T_radeObject->output($T_outfile, $order, $mapping, $all_activate, $all_trade, $A_keyname, $T_keyname);#参数过长，建议优化
