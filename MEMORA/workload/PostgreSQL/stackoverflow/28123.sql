WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        CloseVotes,
        Upvotes,
        Downvotes,
        BadgeCount,
        RANK() OVER (ORDER BY (Upvotes - Downvotes) DESC) AS RankScore
    FROM 
        UserStatistics
)
SELECT 
    t.DisplayName,
    t.QuestionCount,
    t.AnswerCount,
    UPPER(CONCAT(t.DisplayName, ' has ', t.BadgeCount, ' badges.')) AS BadgeMessage,
    t.Upvotes,
    t.Downvotes,
    CASE 
        WHEN t.RankScore <= 5 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    TopUsers t
WHERE 
    t.QuestionCount > 0
ORDER BY 
    t.RankScore;
