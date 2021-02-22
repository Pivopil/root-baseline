const handler = async function (event) {
    console.log(event);
    return {
        statusCode: 200,
        statusDescription: "200 OK",
        isBase64Encoded: false,
        headers: {
            "Content-Type": "application/json; charset=utf-8"
        },
        body: JSON.stringify(event)
    };
};

Object.assign(exports, {handler});
