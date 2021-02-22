const handler = async function (event) {
    return {
        statusCode: 200,
        statusDescription: "200 OK",
        isBase64Encoded: false,
        headers: {
            "Content-Type": "text/html; charset=utf-8"
        },
        "body": JSON.stringify(event)
    }
};

Object.assign(exports, {handler});
