const aws = require('aws-sdk');

const stepfunctions = new aws.StepFunctions();
const ssm = new aws.SSM();

const handler = async function (event) {

    for (const record of event.Records) {
        const { taskToken, Context: { AutomationExecutionId } } = JSON.parse(record.body);
        const { AutomationExecution: { DocumentName, AutomationExecutionStatus }} = await ssm
            .getAutomationExecution({ AutomationExecutionId })
            .promise();
        if (AutomationExecutionStatus === 'InProgress') {
            throw new Error('Incomplete task, retry later...');
        } else {
            return await stepfunctions.sendTaskSuccess({
                output: JSON.stringify({ DocumentName, AutomationExecutionStatus }),
                taskToken: taskToken
            }).promise();
        }
    }
};

Object.assign(exports, {handler});
