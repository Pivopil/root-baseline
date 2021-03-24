const aws = require('aws-sdk');

const ssm = new aws.SSM();

const handler = async function({ DocumentName }) {
    return await ssm.startAutomationExecution({ DocumentName }).promise();
};

Object.assign(exports, { handler });
