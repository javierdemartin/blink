package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "bytes"
    "io/ioutil"
)

type Receipt struct {
    ReceiptData string `json:"receipt-data"`
}

type AppleReceipt struct {
  Status uint64 `json:status`
}

type OfficialReceipt struct {
    ReceiptData string `json:"receipt-data"`
    Password  string `json:"password"`
    ExcludeOldTransactions string `json:"exclude-old-transactions"`

}

type server struct{}

const productionUrl string = "https://buy.itunes.apple.com/verifyReceipt"
const sandboxUrl string = "https://sandbox.itunes.apple.com/verifyReceipt"

var password string = "APP_SECRET"

var p Receipt
var officialReceipt OfficialReceipt

func validateReceiptSendingItToApple(receipt OfficialReceipt, urlEndpoint string) string {

    b, err := json.Marshal(officialReceipt)
    if err != nil {
      fmt.Println(err)
      return ""
    }

    var jsonStr = []byte(string(b))
    req, err := http.NewRequest("POST", urlEndpoint, bytes.NewBuffer(jsonStr))
    req.Header.Set("Content-Type", "application/json")

    client := &http.Client{}

    resp, err := client.Do(req)
    if err != nil {
        panic(err)
    }
    defer resp.Body.Close()

    // The body of the response will be the Receceipt in JSON format returned from Apple
    body, _ := ioutil.ReadAll(resp.Body)

    var appleJsonReceipt = string(body)

    return appleJsonReceipt
}

// Validating against 
func (s *server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    switch r.Method {
    case "GET":
        w.WriteHeader(http.StatusOK)
        w.Write([]byte(`{"message": "get called"}`))
    case "POST":

                err := json.NewDecoder(r.Body).Decode(&p)

                if err != nil {

                    http.Error(w, err.Error(), http.StatusBadRequest)
                    fmt.Printf(">>> post err\n")
                    return
                }

        // Fill the needed JSON contents to submit to the App Store request
        // https://developer.apple.com/documentation/appstorereceipts/requestbody
        officialReceipt.ReceiptData = p.ReceiptData
        officialReceipt.ExcludeOldTransactions = "true"
        officialReceipt.Password = password

        var receiptReturned = validateReceiptSendingItToApple(officialReceipt, productionUrl)

        var appleReceipt AppleReceipt

        json.Unmarshal([]byte(receiptReturned), &appleReceipt)         

        // If code is 21007 you've used the production environment for a sandbox environment
        if appleReceipt.Status == 21007 {
          receiptReturned = validateReceiptSendingItToApple(officialReceipt, sandboxUrl)
        }

        w.WriteHeader(http.StatusOK)
        w.Write([]byte(receiptReturned))

    case "PUT":
        w.WriteHeader(http.StatusAccepted)
        w.Write([]byte(`{"message": "put called"}`))
    case "DELETE":
        w.WriteHeader(http.StatusOK)
        w.Write([]byte(`{"message": "delete called"}`))
    default:
        w.WriteHeader(http.StatusNotFound)
        w.Write([]byte(`{"message": "not found"}`))
    }
}

func main() {
    s := &server{}
    http.Handle("/validateReceipt", s)
    // http.Handle("/validateReceipt", validateReceipt)
    log.Fatal(http.ListenAndServe(":8080", nil))
}
