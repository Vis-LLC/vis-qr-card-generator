/*
    Copyright (C) 2025 Vis LLC - All Rights Reserved

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation, either version 3 of the License, or (at your
    option) any later version.

    You should have received a copy of the GNU General Public License 3
    along with this program.  If not, see <https ://www.gnu.org/licenses/>.
*/

/*
    Vis QR Card Generator
*/

package com.vis.qrcardgenerator;

@:nativeGen
class Generator {
    private var _style = "
        #qrCardGeneratorApp .card {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0;
            border: 1px solid black;
            padding: 0;
        }

        #qrCardGeneratorApp .card-item {
            display: flex;
            flex-direction: column;
            align-items: center;
            margin: 5px;
        }

        #qrCardGeneratorApp .sheet, #qrCardGeneratorApp .sheet-legal {
            display: grid;
            grid-template-columns: repeat(auto-fill, 3.5in);
            grid-auto-rows: 2in;
            margin: 0 auto;
        }    

        #qrCardGeneratorApp {
            font-family: Arial, sans-serif;
        }

        #qrCardGeneratorApp .output img {
            margin: 5px;
        }        

        @media only screen {
            #qrCardGeneratorApp {
                margin: 20px;
            }

            #qrCardGeneratorApp .container {
                margin: 0 auto;
            }

            #qrCardGeneratorApp .form-group {
                margin-bottom: 20px;
            }

            #qrCardGeneratorApp  label {
                display: block;
                margin-bottom: 5px;
            }

            #qrCardGeneratorApp textarea, select, input {
                width: 100%;
                padding: 10px;
                margin-top: 5px;
            }

            #qrCardGeneratorApp button {
                padding: 10px 20px;
                background-color: #007BFF;
                color: white;
                border: none;
                cursor: pointer;
            }

            #qrCardGeneratorApp button:disabled {
                background-color: #cccccc;
                cursor: not-allowed;
            }

            #qrCardGeneratorApp button:hover:not(:disabled) {
                background-color: #0056b3;
            }

            #qrCardGeneratorApp .row {
                margin-bottom: 10px;
                display: flex;
                gap: 10px;
            }

            #qrCardGeneratorApp .row input, .row textarea, .row select {
                flex: 1;
            }

            #qrCardGeneratorApp .row button {
                flex: 0;
            }

            #qrCardGeneratorApp .row.invalid {
                border: 2px solid red;
            }
        }
        @media print {
            @page {
                margin: 0;
            }

            body {
                margin: 0;
                page-break-inside: avoid !important;
                overflow: hidden;
            }

            #qrCardGeneratorApp {
                margin: 0px;
            }

            .panel {
                overflow: hidden;
                width: 100vw;
                height: 100vh;
                top: 0;
                left: 0;
                bottom: 0;
                right: 0;
                border: 0;
                padding: 0;
                margin: 0;
            }

            #qrCardGeneratorApp .output div.card, #qrCardGeneratorApp .output div.sheet {
                display: grid;
            }

            #qrCardGeneratorApp .output div.card-item {
                display: flex;
            }

            div, image, table {
                display: none;
            }

            #qrCardGeneratorApp input, #qrCardGeneratorApp textarea, #qrCardGeneratorApp select, #qrCardGeneratorApp button, #qrCardGeneratorApp label, #qrCardGeneratorApp h1 {
                display: none;
            }

            #qrCardGeneratorApp .output, #qrCardGeneratorApp .output div, #qrcardgenerator, #qrCardGeneratorApp {
                display: block;
            }
        }
    ";

    private var _cardSizes = [
        "business" => "Business Card (3.5\" x 2\")",
        "sheet" => "Sheet (Letter)",
        "sheet-legal" => "Sheet (Legal)",
        "custom" => "Custom"
    ];

    private var _inputTypes = [
        "url" => "URL",
        "email" => "Email",
        "html" => "HTML",
        "labelOnly" => "Label Only"
    ];

    private var _printTypes = [
        "individual" => "Individual Cards",
        "sheet" => "Sheet (Letter)",
        "sheet-legal" => "Sheet (Legal)"
    ];

    private var _printSides = [
        "front" => "One Side Only",
        "both-side" => "Front and Back - Side by Side",
        "both-separate" => "Front and Back - Separate"
    ];

    private var _generateButton : Dynamic;
    private var _printButton : Dynamic;
    private var _downloadButton : Dynamic;
    private var _output : Dynamic;
    private var _addRow : Dynamic;
    private var _element : Dynamic;
    private var _sheet : Dynamic;
    private var _dpi : Int = 96;
    private static var _instance : Generator;

    private function new() {
        loadRequiredScripts();
        buildInterface();
    }

    private static function instance() : Generator {
        if (_instance == null) {
            _instance = new Generator();
        }
        return _instance;
    }

    @:expose
    public static function place(parent : js.html.Element) : Void {
        var element = instance()._element;
        #if JS_BROWSER
            if (element.parentNode != null) {
                element.parentNode.removeChild(element);
            }
            parent.appendChild(element);
        #end
    }

    private function addRow(rowsContainer : js.html.Element) : Void {
        var row = js.Browser.document.createElement('div');
        row.className = "row";
        addSelect(row, _inputTypes);
        var textArea : js.html.TextAreaElement = cast js.Browser.document.createElement('textarea');
        textArea.className = "inputText";
        textArea.rows = 2;
        textArea.placeholder = "Enter your text here...";
        row.appendChild(textArea);
        var labelText : js.html.InputElement = cast js.Browser.document.createElement('input');
        labelText.type = "text";
        labelText.className = "labelText";
        labelText.placeholder = "Enter a label...";
        row.appendChild(labelText);
        var removeButton = js.Browser.document.createElement('button');
        removeButton.className = "removeRow";
        removeButton.textContent = "Remove";
        removeButton.addEventListener('click', function () {
            row.remove();
            resetOutput();
        });
        row.appendChild(removeButton);
        rowsContainer.appendChild(row);
    }

    private function buildInterface() : Void {
        #if JS_BROWSER
            var style : js.html.StyleElement = cast js.Browser.document.createElement("style");
            style.textContent = _style;
            js.Browser.document.head.appendChild(style);
            var element = js.Browser.document.createElement("div");
            element.id = "qrCardGeneratorApp";
            element.appendChild(createTitle());
            _element = element;
            buildRowsContainer();
            _addRow = addButton(element, "Add Row", "addRow");
            _addRow.addEventListener('click', onAddRow);
            addSelectWrapper(element, _cardSizes, "cardSize", "Card Size");
            addCustomSizeGroup(element);
            addMarginSizeGroup(element);
            addSelectWrapper(element, _printTypes, "printType", "Print Type");
            addSelectWrapper(element, _printSides, "printSide", "Print Side");
            _generateButton = addButton(element, "Generate", "generateBtn");
            _generateButton.addEventListener('click', generateContent);
            _printButton = addButton(element, "Print", "printBtn", true);
            _printButton.addEventListener('click', onPrint);
            _downloadButton = addButton(element, "Download", "downloadBtn", true);
            _downloadButton.addEventListener('click', onDownload);
            element = js.Browser.document.createElement("div");
            element.className = "output";
            element.id = "output";
            _output = element;
            _element.appendChild(_output);

            js.Syntax.code("document.querySelectorAll('input, select, textarea').forEach(input => { input.addEventListener('input', resetOutput); });");
        #end
    }

    private function createTitle() : js.html.Element {
        var title : js.html.Element = cast js.Browser.document.createElement("h1");
        title.textContent = "Vis QR Card Generator";
        return title;
    }

    private function addNumberInput(parent : js.html.Element, id : String, labelText : String, placeholder : String) : js.html.InputElement {
        var label : js.html.LabelElement = cast js.Browser.document.createElement("label");
        label.textContent = labelText;
        label.htmlFor = id;
        parent.appendChild(label);
        var input : js.html.InputElement = cast js.Browser.document.createElement("input");
        input.type = "number";
        input.id = id;
        input.placeholder = placeholder;
        parent.appendChild(input);
        input.onchange = resetOutput;
        return input;
    }

    private function addCustomSizeGroup(parent : js.html.Element) : Void {
        var element = js.Browser.document.createElement("div");
        element.className = "form-group";
        element.id = "customSizeGroup";
        element.style.display = "none";
        addNumberInput(element, "customWidth", "Custom Width (inches)", "Width in inches");
        addNumberInput(element, "customHeight", "Custom Height (inches)", "Height in inches");
        parent.appendChild(element);
    }

    private function addMarginSizeGroup(parent : js.html.Element) : Void {
        var element = js.Browser.document.createElement("div");
        element.className = "form-group";
        element.id = "marginSizeGroup";
        addNumberInput(element, "marginLeft", "Margin Left", "Left margin in inches");
        addNumberInput(element, "marginTop", "Margin Top", "Top margin in inches");
        addNumberInput(element, "marginRight", "Margin Right", "Right margin in inches");
        addNumberInput(element, "marginBottom", "Margin Bottom", "Bottom margin in inches");
        addNumberInput(element, "marginVerticalGap", "Margin Vertical Gap", "Vertical gap between cards in inches");
        addNumberInput(element, "marginHorizontalGap", "Margin Horizontal Gap", "Horizontal gap between cards in inches");
        parent.appendChild(element);
    }    

    private function addButton(element : js.html.Element, text : String, id : String, ?disabled : Bool) : js.html.ButtonElement {
        #if JS_BROWSER
            var button : js.html.ButtonElement = cast js.Browser.document.createElement("button");
            button.textContent = text;
            button.id = id;
            if (disabled != null && disabled) {
                button.disabled = true;
            }
            element.appendChild(button);
            return button;
        #end
    }

    private function addSelect(element : js.html.Element, options : Map<String, String>, ?id : String) : Void {
        #if JS_BROWSER
            var select = js.Browser.document.createElement("select");
            if (id != null) {
                select.id = id;
            }
            for (key in options.keys()) {
                var option : js.html.OptionElement = cast js.Browser.document.createElement("option");
                option.value = key;
                option.text = options.get(key);
                select.appendChild(option);
            }
            select.onchange = resetOutput;
            element.appendChild(select);
        #end
    }

    private function addSelectWrapper(parent : js.html.Element, options : Map<String, String>, id : String, labelText : String) : Void {
        #if JS_BROWSER
            var selectWrapper = js.Browser.document.createElement("div");
            selectWrapper.className = "form-group";
            var label : js.html.LabelElement = cast js.Browser.document.createElement("label");
            label.textContent = labelText;
            label.htmlFor = id;
            selectWrapper.appendChild(label);
            addSelect(selectWrapper, options, id);
            parent.appendChild(selectWrapper);
        #end
    }

    private function buildRowsContainer() : Void {
        #if JS_BROWSER
            var rowsContainer = js.Browser.document.createElement("div");
            rowsContainer.id = "rowsContainer";
            addRow(rowsContainer);
            _element.appendChild(rowsContainer);
        #end
    }

    private function loadRequiredScripts() : Void {
        #if JS_BROWSER
            var load : String->Void = function (src : String) : Void {
                var script : js.html.ScriptElement = cast js.Browser.document.createElement("script");
                script.src = src;
                js.Browser.document.head.appendChild(script);
            };
            load("https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js");
            load("https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js");
        #end
    }

    private function onAddRow() : Void {
        #if JS_BROWSER
            var rowsContainer = js.Browser.document.getElementById('rowsContainer');
            addRow(rowsContainer);
            resetOutput();
        #end
    }

    private function onDownload() : Void {
        #if JS_BROWSER
            generateImage(function (canvas) {
                var link : js.html.AnchorElement = cast js.Browser.document.createElement('a');
                link.download = 'qr_cards.png';
                link.href = canvas.toDataURL();
                link.click();
            });
        #end
    }

    private function onPrint() : Void {
        #if JS_BROWSER
            js.Browser.window.print();
        #end
    }

    private function resetOutput() : Void {
        #if JS_BROWSER
            _output.innerHTML = '';
            _printButton.disabled = true;
            _downloadButton.disabled = true;
            _generateButton.disabled = false;
        #end
    }

    private function isValidURL(string : String) : Bool {
        try {
            #if js
                js.Syntax.code("new URL({0})", string);
            #end
            return true;
        } catch (ex : Any) {
            return false;
        }
    }

    private function isValidEmail(email : String) : Bool {
        var emailRegex = ~/^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.match(email);
    }

    private function preprocessInput(inputType : String, inputText : String, row : js.html.HtmlElement) : String {
        if (inputType == 'url' && !isValidURL(inputText)) {
            row.classList.add('invalid');
            return null;
        }
        if (inputType == 'email' && !isValidEmail(inputText)) {
            row.classList.add('invalid');
            return null;
        }
        if (inputType == 'html' && !StringTools.startsWith(StringTools.trim(inputText), "<")) {
            row.classList.add('invalid');
            return null;
        }

        row.classList.remove('invalid');

        switch (inputType) {
            case 'email':
                return 'mailto:' + inputText;
            case 'html':
                return 'data:text/html,' + StringTools.urlEncode(inputText);
            case 'url':
                return inputText;
            case 'labelOnly':
                return inputText;
            default:
                return inputText;
        }
    }

    private function generateImage(callback : Dynamic->Void) : Void {
        var width : Int = Std.parseInt(StringTools.replace(_sheet.style.width, "in", "")) * _dpi;
        var height : Int = Std.parseInt(StringTools.replace(_sheet.style.height, "in", "")) * _dpi;
        js.Syntax.code("html2canvas({0}, {\"width\": {2}, \"height\": {3}}).then(canvas => { {1}(canvas); });", _output, callback, width, height);
    }

    private function getValueFromId(id : String) : String {
        var element : js.html.InputElement = cast js.Browser.document.getElementById(id);
        return element.value;
    }

    private function getRows() : Array<Row> {
        var rows = js.Browser.document.querySelectorAll('.row');
        var result = [];
        for (row in rows) {
            var get : String->String = function (id : String) : String {
                var e : js.html.InputElement = cast js.Syntax.code("{0}.querySelector({1})", row, id);
                return e.value;
            };
            var r = new Row();
            r.inputType = get("select");
            r.inputText = get(".inputText");
            r.labelText = get(".labelText");
            r.preprocessedText = preprocessInput(r.inputType, r.inputText, cast row);
            if (r.preprocessedText == null) {
                return null;
            }
            result.push(r);
        }
        return result;
    }

    private function generateRow(row : Row, card : Dynamic, width : Float, height : Float) : Void {
        if (row.inputText == null) {
            var e : js.html.HtmlElement = cast row;
            e.classList.add("invalid");
            return;
        }

        var label = js.Browser.document.createElement('div');
        label.textContent = row.labelText;
        label.style.textAlign = 'center';

        if (row.inputType != 'labelOnly') {
            var qrCodeDiv = js.Browser.document.createElement('div');
            qrCodeDiv.className = 'card-item';

            var sizeW = width * _dpi / 4;
            var sizeH = height * _dpi / 4;
            var size = sizeW > sizeH ? sizeH : sizeW;
            js.Syntax.code("new QRCode({0}, {{ text: {1}, width: {2}, height: {2} }});", qrCodeDiv, row.preprocessedText, size);
            qrCodeDiv.appendChild(label);
            card.appendChild(qrCodeDiv);
        } else {
            card.appendChild(label);
        }
    }

    private function generateContent() : Void {
        var rows = js.Browser.document.querySelectorAll('.row');
        var cardSize = getValueFromId("cardSize");
        var printType = getValueFromId("printType");
        var printSide = getValueFromId("printSide");
    
        var width = 3.5;
        var height = 2;

        var sheetWidth = 8.5;
        var sheetHeight = 11;
    
        switch (cardSize) {
            case "business":
                width = 3.5;
                height = 2;
            case "sheet":
                width = 8.5;
                height = 11;
            case "sheet-legal":
                width = 8.5;
                height = 14;
            case "custom":
                var customWidth = Std.parseFloat(getValueFromId("customWidth"));
                var customHeight = Std.parseFloat(getValueFromId("customHeight"));
                width = cast customWidth;
                height = cast customHeight;
        }

        switch (printType) {
            case "sheet":
                sheetWidth = 8.5;
                sheetHeight = 11;
            case "sheet-legal":
                sheetWidth = 8.5;
                sheetHeight = 14;
            case "individual":
                sheetWidth = width;
                sheetHeight = height;
        }

        var marginLeft = Std.parseFloat(getValueFromId("marginLeft"));
        var marginTop = Std.parseFloat(getValueFromId("marginTop"));
        var marginRight = Std.parseFloat(getValueFromId("marginRight"));
        var marginBottom = Std.parseFloat(getValueFromId("marginBottom"));
        var marginVerticalGap = Std.parseFloat(getValueFromId("marginVerticalGap"));
        var marginHorizontalGap = Std.parseFloat(getValueFromId("marginHorizontalGap"));

        _output.innerHTML = "";

        var sheetCount : Int = 1;

        switch (printSide) {
            case "both-separate":
                sheetCount = 2;
        }
    
        var sheetI : Int = 0;
        while (sheetI < sheetCount) {
            var container = js.Browser.document.createElement('div');
            container.className = printType == 'sheet-legal' ? 'sheet-legal' : 'sheet';
            container.style.height = sheetHeight + "in";
            container.style.width = sheetWidth + "in";
            container.style.rowGap = marginVerticalGap + "in";
            container.style.columnGap = marginHorizontalGap + "in";
            container.style.paddingTop = marginTop + "in";
            container.style.paddingBottom = marginBottom + "in";
            container.style.paddingLeft = marginLeft + "in";
            container.style.paddingRight = marginRight + "in";
            _output.style.height = sheetHeight + "in";
            _output.style.width = sheetWidth + "in";
            _sheet = container;

            var i : Int = 0;
            var rows : Array<Row> = getRows();

            if (rows == null) {
                return;
            }

            while (i < (StringTools.startsWith(printType, "sheet") ? 10 : 1)) {
                var card = js.Browser.document.createElement('div');
                card.className = 'card';
                card.style.width = width + "in";
                card.style.height = height + "in";

                switch (printSide) {
                    case "front":
                        for (row in rows) {
                            generateRow(row, card, width, height);
                        }
                    case "both-side", "both-separate": {
                            var j : Int;
                            var l : Int;
                            var check : Int = 0;

                            switch (printSide) {
                                case "both-side":
                                    check = i;
                                case "both-separate":
                                    check = sheetI;
                            }

                            if (check % 2 == 0) {
                                j = 0;
                                l = Math.ceil(rows.length / 2);
                            } else {
                                j = Math.ceil(rows.length / 2);
                                l = rows.length;
                            }

                            while (j < l) {
                                generateRow(rows[j], card, width, height);
                                j++;
                            }
                        }
                }
        
                container.appendChild(card);
                i++;
            }
        
            _output.appendChild(container);
            sheetI++;
        }
        _printButton.disabled = false;
        _downloadButton.disabled = false;
        _generateButton.disabled = true;
    }
}

@:nativeGen
class Row {
    public function new() { }

    public var inputType : String;
    public var inputText : String;
    public var preprocessedText : String;
    public var labelText : String;
}