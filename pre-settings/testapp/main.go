package main

import (
	"io"
	"log"
	"net/http"
	"os"
)

func main() {
	http.HandleFunc("/", helloWorld)
	log.Fatal(http.ListenAndServe(":"+os.Getenv("PORT"), nil))
}

func helloWorld(w http.ResponseWriter, req *http.Request) {
	io.WriteString(w, "Hello, world!")
}
