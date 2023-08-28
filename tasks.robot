*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${TRUE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Variables ***
${ORDER_URL}                https://robotsparebinindustries.com/
${ORDER_LINK}               Order your robot!
${ORDER_MODAL}              OK
${CSV_URL}                  https://robotsparebinindustries.com/orders.csv
${CSV_FILE}                 orders.csv
${GLOBAL_RETRY_AMOUNT}      10x
${GLOBAL_RETRY_INTERVAL}    0.5s
${RECEIPTS_FOLDER}          ${TEMPDIR}${/}receipts
${SCREENSHOTS_FOLDER}       ${TEMPDIR}${/}screenshots


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    Loop the orders    ${orders}
    Create ZIP file of receipt PDF files
    Cleanup temporary PDF directory
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    ${ORDER_URL}
    Click Link    ${ORDER_LINK}

Close the annoying modal
    Click Button    ${ORDER_MODAL}

Get orders
    Download    ${CSV_URL}    target_file=${OUTPUT_DIR}${/}${CSV_FILE}    overwrite=${TRUE}
    ${orders}=    Read Table From Csv    ${OUTPUT_DIR}${/}${CSV_FILE}
    RETURN    ${orders}

Loop the orders
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit the order
        ${pdf}=    Export receipt as PDF    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another robot
    END

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text
    ...    xpath://form/div[3]/input
    ...    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    Preview

Submit the order
    Click Button    Order
    Page Should Contain Element    order-another

Export receipt as PDF
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_dest}=    Set Variable    ${RECEIPTS_FOLDER}${/}${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf_dest}
    RETURN    ${pdf_dest}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${screenshot_dest}=    Set Variable    ${SCREENSHOTS_FOLDER}${/}${order_number}.png
    Screenshot    id:robot-preview-image    ${screenshot_dest}
    RETURN    ${screenshot_dest}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open PDF    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}
    Close Pdf    ${pdf}

Order another robot
    Click Button    Order another robot

Create ZIP file of receipt PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${RECEIPTS_FOLDER}    ${zip_file_name}

Cleanup temporary PDF directory
    Remove Directory    ${RECEIPTS_FOLDER}    True
    Remove Directory    ${SCREENSHOTS_FOLDER}    True
