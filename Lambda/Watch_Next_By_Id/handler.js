const connect_to_db = require('./db');

// GET BY TALK HANDLER

const talk = require('./Talk');

module.exports.get_wn_by_id = (event, context, callback) => {
    context.callbackWaitsForEmptyEventLoop = false;
    console.log('Received event:', JSON.stringify(event, null, 2));
    let body = {}
    if (event.body) {
        body = JSON.parse(event.body)
    }
    // set default
    if(!body._id) {
        callback(null, {
                    statusCode: 500,
                    headers: { 'Content-Type': 'text/plain' },
                    body: 'Could not fetch the talks. idx is null.'
        })
    }

    connect_to_db().then(() => {
        console.log('=> get_all talks');
        talk.find({_id: body._id})
            .then(talks => {
                
                        talks[0].watch_next.sort((a, b) => parseInt(b.watch_next_views)-parseInt(a.watch_next_views))
                        callback(null, {
                        statusCode: 200,
                        body: JSON.stringify({watch_next: talks[0].watch_next})
                    })
                })
            .catch(err =>
                callback(null, {
                    statusCode: err.statusCode || 500,
                    headers: { 'Content-Type': 'text/plain' },
                    body: 'Could not fetch the talks.'
                })
            );
    });
};
