#读取excel，遍历最大范围的行列，并输出为新的txt
#遍历"./data"目录并把里面所有的xlsx文件转化为txt，输出在./trans
#只输出唯一的sheet

#标准错误和标准输出写入log.txt文件
#目前用cmd错误输出到run.log,用perl的标准错误输出到log.txt
open STDOUT,">>log.txt" or die "can not open log.txt";
open STDERR,">>log.txt" or die "can not open log.txt";
use Encode;#处理编码
###遍历data目录下所有xlsx文件，生成文件句柄，打印结果###
opendir DIR,"./data" or die "can not open dir, $!";;
$time = localtime();#记录时间
print "__________ $time __________\n";#日志文件抬头,一边10个_
foreach (sort grep(/^.*\.xlsx$/,readdir(DIR))){
	my $file = $_;#这里是文件名，也做文件句柄
	my $pattern = &hand("ID映射表");
	if(/$pattern/){#ID映射表特殊命名，且不影响其他文件处理
		open $file,">:encoding(utf-8)", "./trans/mapID.txt";
		$FILEHANDLE{$file} = "./trans/mapID.txt";#保存文件句柄=文件名
	}
	else{
		my $tempname = ".\/trans\/".$file.'.txt';#用临时变量组合文件名，不然后文if无法识别
		open $file,">:encoding(utf-8)", $tempname;#其他文件转换结果
		$FILEHANDLE{$file} = $tempname;#保存文件句柄=文件名
	}
	print "get \"$file\" successfully\n";#输出标志完成信息
}
closedir DIR;

###对xlsx文件进行解析和转换
require Spreadsheet::ParseXLSX;#解析xlsx的包，注意，使用use无法在打包后正确找到这个包！！！
for(keys %FILEHANDLE){#遍历文件句柄，以逐个解析
	my $filename = $_;#不同xlsx文件的文件句柄(包括mapID)
	my $parser = Spreadsheet::ParseXLSX->new;#看不懂这句，官方文档写的
	my $workbook = $parser->parse("./data/$filename");#这里取出了工作表
	$worksheet = $workbook->worksheet(0);#默认取出工作表中第一个sheet，
	my ( $row_min, $row_max ) = $worksheet->row_range();
	my ( $col_min, $col_max ) = $worksheet->col_range();
	#循环取出每个单元格的值
	for(0..$row_max){
		$row = $_;
		for(0..$col_max){
			$col = $_;
			my $cell = $worksheet->get_cell($row,$col);
			my $value = $cell->value() if(defined $cell);#防止单元格为空
			push @shelf,$value;
		}
		$shelf = join "\t",@shelf;#输出格式
		print $filename "$shelf\n";#写入$filename文件
		undef @shelf;#清空数组反复利用
	}
	if (-e $FILEHANDLE{$filename}){#
		print "Format \"$filename\" to \"$FILEHANDLE{$filename}\"\n";#输出转换信息
		close $filename;
	}
}
#print "______________________ END ______________________\n";#一边22个_
sub hand{#减少重复输入的子程序(函数)
		encode("gbk", decode("utf8",@_[0]));
}