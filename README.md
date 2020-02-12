# Open_In_Windows_Terminal
 adapted from [yangshuairocks/Open_in_Windows_Terminal](https://github.com/yangshuairocks/Open_in_Windows_Terminal)

if you want a Help in English, yangshuairocks version is better, the script is adapt from his version and the effect is almost the same (my English is not good......)

## 使用方法：
双击运行install脚本（中途会申请管理员权限，同时注意控制台的提示信息），完成后会在当前目录下生成两个注册表文件，一个是用于注入非管理员权限运行的，一个是用于注入管理员权限的，注入完成后就可以在右键菜单中看到了

## 还原脚本效果：
双击运行uninstall脚本，等待运行完成后会生成两个以uninstall为前缀的reg文件，双击注入后即可还原

## 脚本做了什么？
往你的powershell的配置文件目录(此电脑\文档\WindowsPowershell)写入了三个脚本

Microsoft.PowerShell_profile.ps1

PowerShell_openByNoAdmin.ps1

PowerShell_openByAdmin.ps1

其中Microsoft.PowerShell_profile.ps1是powershell本身的启动配置脚本，如果这个脚本原来有东西的话，会进行一定的处理，不会影响到原来脚本的运行

相应的，在注册表中加入键值来实现右键调用另外两个启动脚本，从名字都可以看得出来，一个是非管理员的，一个是管理员的（为什么要这么区分？因为UAC太烦了，不够利落，但关掉也不好）

注册表项如下:

`[HKEY_CLASSES_ROOT\*\shell\]` 这个是右键选择文件的相关项

`[HKEY_CLASSES_ROOT\Directory\Background\shell\]` 这个是右键选择空白处的相关项

`[HKEY_CLASSES_ROOT\Directory\shell\]` 这个是右键选择目录的相关项

会在这三个目录下加入WindowsTerminal的键，管理员的话有ByAdmin后缀

然后还原脚本就是反向操作啦

## 大致思路

1. 右键的时候，会向系统传入参数，其中路径在注册表中的体现就是%V参数，然后再将这个参数传入脚本，脚本将该路径放入一个临时文件（同时这个文件的名字中会包含是否用管理员启动的信息），随后，启动powershell

2. powershell启动后，会读取它自己的配置脚本，我们在配置脚本中加入逻辑判断：如果有那个存放路径的临时文件的话，就将其拿出（此时判断要不要用管理员启动），并设置为当前路径，然后删除文件；然后无论有没有临时文件，都将进行用户本身自定义的powershell启动配置

> 欢迎去和程序的原作者yangshuairocks交流（为什么，因为我太菜了，这个程序是在他的基础上改的，想法是他的）