# Costco Importer

The primary goal is to convert Costco's In-Warehouse receipts from `costco.com`
into a structure that can be easily imported into Google Sheets.

- Compute tax at a per item level. Many receipts lump all the tax together—it's
  much easier to calculate it that way—but, I do need to know the "final" price
  per item and thus need to compute the tax per item.

- Costco handles discounts is a very odd way. Discounts on items are an entirely
  separate line item that needs to be manually associated with the purchased
  item. One goal for this project is to automatically associate discounts and
  compute the total price of each item (after discount and tax).

- Separate items with multiple units/quanities into separate line items. For
  example, if I buy 3 boxes of cereal, I want to see 3 line items for that
  cereal.


## Raw Data

The data coming from Costco is in two following formats: text or JSON. I'll just
be using the JSON

### Text

```text
Member 1234567890
E	1357244	CNBY WLNT B	8.99 N
6262016	**KS BATH**	19.49 Y
E	96716	ORG SPINACH	4.99 N
E	1360840	OMEGA EGGS	6.89 N
E	150	SOY SAUCE	6.69 N
E	121288	ORG BELLAS	5.99 N
E	184882	RUFFLES CHE	7.89 N
E	60357	MIXED PEPPE	8.99 N
E	737160	KIMCHI	7.89 N
E	1745439	REESE POPCR	7.89 N
E	748273	IVAR CHOWDE	11.69 N
E	1705316	MEATBALL	29.38 N
1680380	MICHBLADE26	10.99 Y
317892	/MICHELIN	3.00-
E	131453	CHKN CHIMI	39.98 N
E	1398257	SHRIMP CHIP	8.89 N
E	1710454	KEW MAYO	5.99 N
E	202195	SPAM LO-SAL	45.98 N
E	162274	CHUNK LTTUN	17.69 N
E	9929	KS CHIC TOR	8.59 N
E	1355725	NAE POT PIE	13.99 N
E	207	CALROSE RIC	16.99 N
E	1367121	RED PEP SPR	8.59 N
1680375	MICHBLADE19	10.99 Y
317892	/MICHELIN	3.00-
E	1015237	KS STIR FRY	9.99 N
E	47825	GREEN GRAPE	26.97 N
SUBTOTAL	346.40
TAX	3.64
****	TOTAL	350.04
```

### JSON

This JSON can be found by inspecting the site's network traffic. When opening a
receipt, it makes a request to a GraphQL endpoint

```json
{
  "data": {
    "receipts": [
      {
        "warehouseName": "SEATTLE",
        "documentType": "WarehouseReceiptDetail",
        "transactionDateTime": "2023-12-12T15:58:00",
        "transactionDate": "2023-12-12",
        "companyNumber": 1,
        "warehouseNumber": 1,
        "operatorNumber": 64,
        "warehouseShortName": "SEATTLE",
        "registerNumber": 12,
        "transactionNumber": 123,
        "transactionType": "Sales",
        "transactionBarcode": "1234567890",
        "total": 350.04,
        "warehouseAddress1": "4401 4TH AVE S",
        "warehouseAddress2": null,
        "warehouseCity": "SEATTLE",
        "warehouseState": "WA",
        "warehouseCountry": "US",
        "warehousePostalCode": "98134",
        "totalItemCount": 30,
        "subTotal": 346.4,
        "taxes": 3.64,
        "itemArray": [
          {
            "itemNumber": "1357244",
            "itemDescription01": "CNBY WLNT BD",
            "frenchItemDescription1": null,
            "itemDescription02": null,
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 8.99,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 62
          },
          {
            "itemNumber": "6262016",
            "itemDescription01": "**KS BATH**",
            "frenchItemDescription1": null,
            "itemDescription02": "1425 SQFT P30 W/US P66",
            "frenchItemDescription2": null,
            "itemIdentifier": null,
            "unit": 1,
            "amount": 19.49,
            "taxFlag": "Y",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 14
          },
          {
            "itemNumber": "96716",
            "itemDescription01": "ORG SPINACH",
            "frenchItemDescription1": null,
            "itemDescription02": "453 G / 16 OZ",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 4.99,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 65
          },
          {
            "itemNumber": "1360840",
            "itemDescription01": "OMEGA EGGS",
            "frenchItemDescription1": null,
            "itemDescription02": "SL21 GRADE AA",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 6.89,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 17
          },
          {
            "itemNumber": "150",
            "itemDescription01": "SOY SAUCE",
            "frenchItemDescription1": null,
            "itemDescription02": "1.89L #00150         P240",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 6.69,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 13
          },
          {
            "itemNumber": "121288",
            "itemDescription01": "ORG BELLAS",
            "frenchItemDescription1": null,
            "itemDescription02": null,
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 5.99,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 65
          },
          {
            "itemNumber": "184882",
            "itemDescription01": "RUFFLES CHED",
            "frenchItemDescription1": null,
            "itemDescription02": "P120 T40H3",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 7.89,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 12
          },
          {
            "itemNumber": "60357",
            "itemDescription01": "MIXED PEPPER",
            "frenchItemDescription1": null,
            "itemDescription02": "6-PACK",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 8.99,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 65
          },
          {
            "itemNumber": "737160",
            "itemDescription01": "KIMCHI",
            "frenchItemDescription1": null,
            "itemDescription02": "6/42.3 OZ   10T8H   SL75",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 7.89,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 19
          },
          {
            "itemNumber": "1745439",
            "itemDescription01": "REESE POPCRN",
            "frenchItemDescription1": null,
            "itemDescription02": "T42L3 P126 SL110",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 7.89,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 12
          },
          {
            "itemNumber": "748273",
            "itemDescription01": "IVAR CHOWDER",
            "frenchItemDescription1": null,
            "itemDescription02": "8/2-24OZ T10H7 SL50",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 11.69,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 19
          },
          {
            "itemNumber": "1705316",
            "itemDescription01": "MEATBALL",
            "frenchItemDescription1": null,
            "itemDescription02": "12/46 OZ    6T5H    SL30",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 2,
            "amount": 29.38,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 19
          },
          {
            "itemNumber": "1680380",
            "itemDescription01": "MICHBLADE26",
            "frenchItemDescription1": null,
            "itemDescription02": "BLADE GUARDIAN+",
            "frenchItemDescription2": null,
            "itemIdentifier": null,
            "unit": 1,
            "amount": 10.99,
            "taxFlag": "Y",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 25
          },
          {
            "itemNumber": "317892",
            "itemDescription01": "/MICHELIN",
            "frenchItemDescription1": "/1680380",
            "itemDescription02": null,
            "frenchItemDescription2": null,
            "itemIdentifier": null,
            "unit": -1,
            "amount": -3,
            "taxFlag": null,
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 25
          },
          {
            "itemNumber": "131453",
            "itemDescription01": "CHKN CHIMI",
            "frenchItemDescription1": null,
            "itemDescription02": "5 OZ EL MONTEREY T8H3P144",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 2,
            "amount": 39.98,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 18
          },
          {
            "itemNumber": "1398257",
            "itemDescription01": "SHRIMP CHIPS",
            "frenchItemDescription1": null,
            "itemDescription02": "P96 SL360",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 8.89,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 12
          },
          {
            "itemNumber": "1710454",
            "itemDescription01": "KEW MAYO",
            "frenchItemDescription1": null,
            "itemDescription02": "T10H5  SL 270  P800",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 5.99,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 13
          },
          {
            "itemNumber": "202195",
            "itemDescription01": "SPAM LO-SALT",
            "frenchItemDescription1": null,
            "itemDescription02": "T25H10  SL270       P250",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 2,
            "amount": 45.98,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 13
          },
          {
            "itemNumber": "162274",
            "itemDescription01": "CHUNK LTTUNA",
            "frenchItemDescription1": null,
            "itemDescription02": "SL540 DOM3YRS        P336",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 17.69,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 13
          },
          {
            "itemNumber": "9929",
            "itemDescription01": "KS CHIC TORT",
            "frenchItemDescription1": null,
            "itemDescription02": "2/830ML CNSL50  SL60 10X4",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 8.59,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 19
          },
          {
            "itemNumber": "1355725",
            "itemDescription01": "NAE POT PIE",
            "frenchItemDescription1": null,
            "itemDescription02": "MARIE CALLEN C6T6H3P108",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 13.99,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 18
          },
          {
            "itemNumber": "207",
            "itemDescription01": "CALROSE RICE",
            "frenchItemDescription1": null,
            "itemDescription02": "FANCY MEDIUM GRAIN    P80",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 16.99,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 13
          },
          {
            "itemNumber": "1367121",
            "itemDescription01": "RED PEP SPRD",
            "frenchItemDescription1": null,
            "itemDescription02": "12/32.6OZ SL270 9T8H",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 8.59,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 19
          },
          {
            "itemNumber": "1680375",
            "itemDescription01": "MICHBLADE19",
            "frenchItemDescription1": null,
            "itemDescription02": "BLADE GUARDIAN+",
            "frenchItemDescription2": null,
            "itemIdentifier": null,
            "unit": 1,
            "amount": 10.99,
            "taxFlag": "Y",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 25
          },
          {
            "itemNumber": "317892",
            "itemDescription01": "/MICHELIN",
            "frenchItemDescription1": "/1680375",
            "itemDescription02": null,
            "frenchItemDescription2": null,
            "itemIdentifier": null,
            "unit": -1,
            "amount": -3,
            "taxFlag": null,
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 25
          },
          {
            "itemNumber": "1015237",
            "itemDescription01": "KS STIR FRY",
            "frenchItemDescription1": null,
            "itemDescription02": "P216 6X6",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 1,
            "amount": 9.99,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 18
          },
          {
            "itemNumber": "47825",
            "itemDescription01": "GREEN GRAPES",
            "frenchItemDescription1": null,
            "itemDescription02": "1.36 KG / 3 LB",
            "frenchItemDescription2": null,
            "itemIdentifier": "E",
            "unit": 3,
            "amount": 26.97,
            "taxFlag": "N",
            "merchantID": null,
            "entryMethod": null,
            "transDepartmentNumber": 65
          }
        ],
        "tenderArray": [
          {
            "tenderTypeCode": "123",
            "tenderDescription": "VISA",
            "amountTender": 350.04,
            "displayAccountNumber": 1234,
            "sequenceNumber": null,
            "approvalNumber": null,
            "responseCode": null,
            "transactionID": null,
            "merchantID": null,
            "entryMethod": null
          }
        ],
        "couponArray": [
          {
            "upcnumberCoupon": "1234567890",
            "voidflagCoupon": null,
            "refundflagCoupon": null,
            "taxflagCoupon": null,
            "amountCoupon": null
          }
        ],
        "subTaxes": {
          "tax1": null,
          "tax2": null,
          "tax3": null,
          "tax4": null,
          "aTaxPercent": null,
          "aTaxLegend": "A",
          "aTaxAmount": 3.64,
          "bTaxPercent": null,
          "bTaxLegend": null,
          "bTaxAmount": null,
          "cTaxPercent": null,
          "cTaxLegend": null,
          "cTaxAmount": null,
          "dTaxAmount": null
        },
        "instantSavings": 6,
        "membershipNumber": "1234567890"
      }
    ]
  }
}
```