# Task 2

## Download qlora_lora_tinyllama.zip from [drive_link]()


## Upload serve_api.ipynb and qlora_lora_tinyllama.zip to MyDrive 
## Open serve_api.ipynb in colab
## Follow instructions in Notebook

`or`

## Create and activate virtual environment prefer python 3.13.9
## install requirements -
- create `./temp` directory
- if normal pip install command through error then run `TMPDIR=./temp pip install -r requirements.txt` 
## Unzip qlora_lora_tinyllama.zip
## launch server with `uvicorn main:app`

## Request format for api

```
curl -X POST "http://localhost:8000/login?username=admin&password=admin123"
```

```
curl -G "http://localhost:8000/recipe" \
    -H "x-api-key: mysecretkey123" \
    --data-urlencode "ingredients=Egg,Onions"
```