<!-- PROJECT LOGO -->
<br />
<div align="center">
    <img src="images/btg_logo.png" alt="Logo" width="140" height="140">
  </a>
  </div>
  
# TITLE
 
## National Stop and Search

This Rproject contains the scripts and data necessary to produce the methods, procedure, and results for Black Thrive Global's National Stop and Search analysis. 

The aim of this analysis is to explore quantify racial disparities in the use of stop and search at national and local authority levels. The project is in ongoing development and the code and statistics presented are subject to change.

## Requirements

### Programs

RStudio is required to open and run the analysis. This project was produced using 

- RStudio 2021.09.0 Build 351 "Ghost Orchid"
- R version 4.1.1

### Packages required

The script uses the following R packages. These need to be installed using <b>install.packages("</b>package name<b>")</b> if they are not already installed on your system.

For analysis script:

- tidyverse
- gmodels
- epitools
- kableExtra
- DT

## Setup

Once downloaded, unzip to a destination of your choice. Note that the **national_dataset_with_forces.csv** data also needs to be unzipped, with the resulting csv file being located in the ***data*** directory. Be sure to retain the original folder structure.

Use **national_stop_search.Rproj** to open project. 

The only analysis to date is the one to supplement a recent Black Thrive blog post. To load the analysis script, use *File > Open File*, navigate to the ***scripts*** folder, and select **analysis_for_blog.Rmd**. To run the script, select *Run > Run all* (Ctrl + Alt + R [Windows]; Cmd + Option + R[Mac]).

If you just want to view the knitted html document with the results, using your system file navigator navigate to the scripts folder and open **analysis_for_blog.html** in your preferred browser.



## Contact

If you have any questions, comments, or feedback please contact the Research Team at Black Thrive: research@blackthrive.org, FAO Dr Jolyon Miles-Wilson.
