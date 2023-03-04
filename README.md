# [Source codes for the dcGO database in 2023](https://github.com/hfang-bristol/dcGO)

## @ Overview

> The [dcGO](http://www.protdomainonto.pro/dcGO) database offers a comprehensive mapping of `protein domains` to `ontologies`.

> The dcGO update in 2023 extends annotations for protein domains from different definitions/levels (SCOP, Pfam, and InterPro) using commonly-used ontologies (categorised into functions, phenotypes, diseases, drugs, pathways, regulators, and hallmarks). This update adds new dimensions to the utility of both ontology and protein domain resources.

> A new website has been launched to provide users with a more integrated and user-friendly experience. This website features: enhanced [faceted search](http://www.protdomainonto.pro:3080/dcGO) capabilities that return term- and domain-specific information pages; improved [ontology hierarchy](http://www.protdomainonto.pro:3080/dcGO/hie) capabilities that browse both ontology terms and their annotated domains; and a newly added facility that  supports [domain-based ontology enrichment analysis](http://www.protdomainonto.pro:3080/dcGO/enrichment).

> To learn how to use the dcGO database, a User manual has been made available [here](http://www.protdomainonto.pro:3080/dcGObooklet/index.html) with step-by-step instructions.

## @ Development

> The dcGO website was developed using a Perl real-time web framework [Mojolicious](https://www.mojolicious.org).

> The dcGO website was also developed using [Bootstrap](https://getbootstrap.com) that supports a mobile-first and responsive webserver across all major platform browsers.

> The folder `my_dcgo` has a tree-like directory structure with three levels:
```ruby
my_dcgo
├── lib
│   └── My_dcgo
│       └── Controller
├── public
│   ├── app
│   │   ├── ajex
│   │   ├── css
│   │   ├── examples
│   │   ├── img
│   │   └── js
│   ├── dcGObooklet
│   │   ├── index_files
│   │   └── libs
│   └── dep
│       ├── HighCharts
│       ├── Select2
│       ├── bootstrap
│       ├── bootstrapselect
│       ├── bootstraptoggle
│       ├── dataTables
│       ├── fontawesome
│       ├── jcloud
│       ├── jqcloud
│       ├── jquery
│       ├── tabber
│       └── typeahead
├── script
├── t
└── templates
    └── layouts
```


## @ Installation

Assume you have a `ROOT (sudo)` privilege on `Ubuntu`

### 1. Install Mojolicious and other perl modules

```ruby
sudo su
# here enter your password

curl -L cpanmin.us | perl - Mojolicious
perl -e "use Mojolicious::Plugin::PODRenderer"
perl -MCPAN -e "install Mojolicious::Plugin::PODRenderer"
perl -MCPAN -e "install DBI"
perl -MCPAN -e "install Mojo::DOM"
perl -MCPAN -e "install Mojo::Base"
perl -MCPAN -e "install LWP::Simple"
perl -MCPAN -e "install JSON::Parse"
perl -MCPAN -e "install local::lib"
perl -MCPAN -Mlocal::lib -e "install JSON::Parse"
```

### 2. Install R

```ruby
sudo su
# here enter your password

# install R
wget http://www.stats.bris.ac.uk/R/src/base/R-4/R-4.2.0.tar.gz
tar xvfz R-4.2.0.tar.gz
cd ~/R-4.2.0
./configure
make
make check
make install
R # start R
```

### 3. Install pandoc

```ruby
sudo su
# here enter your password

# install pandoc
wget https://github.com/jgm/pandoc/releases/download/2.18/pandoc-2.18-linux-amd64.tar.gz
tar xvzf pandoc-2.18-linux-amd64.tar.gz --strip-components 1 -C /usr/local/

# use pandoc to render R markdown
R
rmarkdown::pandoc_available()
Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
rmarkdown::render(YOUR_RMD_FILE, bookdown::html_document2(number_sections=F, theme="readable", hightlight="default"))
```


## @ Deployment

Assume you place `my_dcgo` under your `home` directory

```ruby
cd ~/my_dcgo
systemctl restart apache2.service
morbo -l 'http://*:3080/' script/my_dcgo
```

## @ Contact

> For any bug reports, please drop [email](mailto:fh12355@rjh.com.cn).


