WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        QuestionsAsked,
        AnswersGiven,
        UpVotesReceived,
        DownVotesReceived,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM
        UserStats
)
SELECT
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    QuestionsAsked,
    AnswersGiven,
    UpVotesReceived,
    DownVotesReceived
FROM
    TopUsers
WHERE
    ReputationRank <= 10
ORDER BY
    Reputation DESC;
