# grafana-import-export

Simple scripts to export from, and import dashboards to [Grafana](http://grafana.org/)
Support organizations.

Example was taken from https://gist.github.com/crisidev/bd52bdcc7f029be2f295 

## Dependencies
**[JQ](https://stedolan.github.io/jq/)** - to process .json

## dashboard-exporter
To make it work, you need to replace **HOST** and **FILE_DIR** variables with your own. And fill **ORGS** array with pairs ORGANIZATION:API_KEY

Do not forget to set permissions before run
```
chmod 755 dashboard-exporter.sh
```

Then run:
```
./dashboard-exporter.sh
```

Expected output:
```
./dashboard-exporter.sh
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 21102    0 21102    0     0  53000      0 --:--:-- --:--:-- --:--:-- 53020

```

Look for exported .json dashboards at **FILE_DIR** path

## dashboard-importer
To make it work, you need to replace **HOST** and **FILE_DIR** variables with your own. And fill **ORGS** array with pairs ORGANIZATION:API_KEY

Do not forget to set permissions before run
```
chmod 755 dashboard-importer.sh
```

To import all .json files from **FILE_DIR** to your Grafana:
```
./dashboard-importer.sh
```

To import only some of them:
```
./dashboard-importer.sh organization/dashboard1.json organization/dashboard2.json
```

To import all for organization:
```
./dashboard-importer.sh organization/*.json
```