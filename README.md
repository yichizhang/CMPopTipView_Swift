# CMPopTipView_Swift

I've been very interested in the implementation of [CMPopTipView](https://github.com/chrismiles/CMPopTipView). So I rewrote it in Swift to learn its implementation and also practise iOS programming.

<br/>

![Screenshot](https://raw.githubusercontent.com/yichizhang/CMPopTipView_Swift/master/Screenshots/screenshot1.png)
![Screenshot](https://raw.githubusercontent.com/yichizhang/CMPopTipView_Swift/master/Screenshots/screenshot2.png)
![Screenshot](https://raw.githubusercontent.com/yichizhang/CMPopTipView_Swift/master/Screenshots/screenshot3.png)

# Introduction

CMPopTipView is an iOS UIView subclass that displays a rounded rectangle "bubble", containing a text message, pointing at a specified button or view.

A CMPopTipView will automatically position itself within the view so that it is pointing at the specified button or view, positioning the "pointer" as necessary.

A CMPopTipView can be pointed at any UIView within the containing view. It can also be pointed at a UIBarButtonItem within either a UINavigationBar or a UIToolbar and it will automatically position itself to point at the target.

The background and text colors can be customised if the defaults are not suitable.

Two animation options are available for when a CMPopTipView is presented: "slide" and "pop".

A CMPopTipView can be dismissed by the user tapping on it. It can also be dismissed programatically.

CMPopTipView is rendered entirely by Core Graphics.

The source includes a universal (iPhone/iPad) demo app.

一个泡泡风格的提示框开源控件, 继承自UIView。iPad, iPhone通用。

# Attribution

This project is based on [CMPopTipView](https://github.com/chrismiles/CMPopTipView) by Chris Miles <miles.chris@gmail.com>.

