
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersGiven,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentsMade,
        COALESCE(SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserScore AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation + (QuestionsAsked * 5) + (AnswersGiven * 10) + (CommentsMade * 3) + (BadgesReceived * 20) AS TotalScore
    FROM 
        UserActivity
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserScore
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ua.QuestionsAsked,
    ua.AnswersGiven,
    ua.CommentsMade,
    ua.BadgesReceived,
    t.TotalScore,
    t.Rank,
    CASE 
        WHEN t.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    UserActivity ua
JOIN 
    TopUsers t ON ua.UserId = t.UserId
JOIN 
    Users u ON ua.UserId = u.Id
WHERE 
    u.LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
ORDER BY 
    t.Rank;
