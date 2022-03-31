---
title: 联机托管说明
permalink: index.html
layout: home
ms.openlocfilehash: c906809bcfcfd6cfac0139d9c6d9432cff05fbf1
ms.sourcegitcommit: 5e9f89d47b27285feaf13cacfa097ddd4b888a90
ms.translationtype: HT
ms.contentlocale: zh-CN
ms.lasthandoff: 01/14/2022
ms.locfileid: "137892877"
---
# <a name="content-directory"></a>内容目录

下面列出了每个实验室练习和演示的超链接。

## <a name="labs"></a>实验室

{% assign labs = site.pages | where_exp:"page", "page.url contains '/Instructions/Labs'" %}
| 模块 | 实验室 |
| --- | --- | 
{% 表示实验室 % 中的活动}| {{ activity.lab.module }} | [{{ activity.lab.title }}{% if activity.lab.type %} - {{ activity.lab.type }}{% endif %}]({{ site.github.url }}{{ activity.url }}) |
{% endfor %}

{% comment %}
<!-- Comment out the Jekyll template that lists the placeholder demo -->

## <a name="demos"></a>演示

{% assign demos = site.pages | where_exp:"page", "page.url contains '/Instructions/Demos'" %}
| 模块 | 演示 |
| --- | --- | 
{% for activity in demos  %}| {{ activity.demo.module }} | [{{ activity.demo.title }}]({{ site.github.url }}{{ activity.url }}) |
{% endfor %}

{% endcomment %}
