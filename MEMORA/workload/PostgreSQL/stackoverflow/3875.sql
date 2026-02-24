
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), TopBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS TopBadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1
    GROUP BY 
        b.UserId
), UserRanking AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.QuestionCount,
        us.AnswerCount,
        us.AcceptedAnswerCount,
        tb.TopBadgeNames,
        RANK() OVER (ORDER BY us.Reputation DESC) AS Rank
    FROM 
        UserStats us
    LEFT JOIN 
        TopBadges tb ON us.UserId = tb.UserId
)
SELECT 
    ur.Rank,
    ur.DisplayName,
    ur.Reputation,
    ur.QuestionCount,
    ur.AnswerCount,
    ur.AcceptedAnswerCount,
    COALESCE(ur.TopBadgeNames, 'No Gold Badges') AS TopBadgeNames,
    CASE 
        WHEN ur.Reputation > 1000 THEN 'High Reputation User' 
        ELSE 'Newbie User' 
    END AS UserCategory,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = ur.UserId AND v.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = ur.UserId AND v.VoteTypeId = 3) AS DownvoteCount
FROM 
    UserRanking ur
WHERE 
    ur.QuestionCount > 0
ORDER BY 
    ur.Rank
LIMIT 10;
