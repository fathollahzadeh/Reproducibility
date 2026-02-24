
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived,
        COUNT(c.Id) AS CommentsCount,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT p.AcceptedAnswerId) AS AcceptedAnswersCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotesReceived,
        DownVotesReceived,
        CommentsCount,
        PostsCount,
        AcceptedAnswersCount,
        Rank
    FROM 
        UserActivity
    WHERE 
        Rank <= 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.UpVotesReceived,
    tu.CommentsCount,
    tu.PostsCount,
    tu.AcceptedAnswersCount,
    CASE 
        WHEN tu.DownVotesReceived > tu.UpVotesReceived THEN 'More Negative Feedback'
        ELSE 'More Positive Feedback'
    END AS FeedbackAnalysis
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId AND b.Class = 1
WHERE 
    b.Id IS NULL
ORDER BY 
    tu.Reputation DESC;
