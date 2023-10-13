BeforeAll {
    Import-Module "$PSScriptRoot\..\src\ValidateJson.psd1" -Force
}

Describe "Json ParameterSet" {
    BeforeAll {
        $validJson = '{"key":"value"}'
        $invalidJson = '{"key:"value"}'
    }

    It "Handle pipeline input" {
        $validJson | Test-Json | Should -BeTrue
        $invalidJson | Test-Json | Should -Not -BeTrue
    }
    It "Handle positional argument" {
        Test-Json $validJson | Should -BeTrue
        Test-Json $invalidJson | Should -Not -BeTrue
    }
    It "Handle explicit argument" {
        Test-Json -Json $validJson | Should -BeTrue
        Test-Json -Json $invalidJson | Should -Not -BeTrue
    }
}

Describe "Schema ParameterSet" {
    BeforeAll {
        $Schema = '{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://example.com/product.schema.json","title":"Product","description":"A product from Acme catalog","type":"object","properties":{"price":{"exclusiveMinimum":0,"description":"The price of the product","type":"number"},"productName":{"description":"Name of the product","type":"string"},"productId":{"description":"The unique identifier for a product","type":"integer"}},"required":["productId","productName","price"]}'

        $validJson = '{"productId":2,"productName":"toast","price":3.40}'
        $invalidJson = '{"key:"value"}'
    }

    It "Handle pipeline input" {
        $validJson | Test-Json -Schema $schema | Should -BeTrue
        $invalidJson | Test-Json -Schema $schema | Should -Not -BeTrue
    }
    It "Handle positional argument" {
        Test-Json $validJson -Schema $schema | Should -BeTrue
        Test-Json $invalidJson -Schema $schema | Should -Not -BeTrue
    }
    It "Handle explicit argument" {
        Test-Json -Json $validJson -Schema $schema | Should -BeTrue
        Test-Json -Json $invalidJson -Schema $schema | Should -Not -BeTrue
    }
}