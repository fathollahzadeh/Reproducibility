
WITH RecursiveTopAnswers AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.ParentId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 
),
TopAnswers AS (
    SELECT 
        PostId,
        Title,
        OwnerUserId,
        Score
    FROM 
        RecursiveTopAnswers
    WHERE 
        Rank = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoreCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostInteractionStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges,
    qs.QuestionCount,
    qs.PositiveScoreCount,
    qs.NegativeScoreCount,
    p.Title AS TopAnswerTitle,
    p.Score AS TopAnswerScore,
    pi.CommentCount,
    pi.VoteCount
FROM 
    UserStats qs
JOIN 
    Users u ON qs.UserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    TopAnswers p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostInteractionStats pi ON p.PostId = pi.PostId
WHERE 
    u.Reputation > 1000 
    AND EXISTS (SELECT 1 FROM Posts p2 WHERE p2.OwnerUserId = u.Id AND p2.PostTypeId = 1)
ORDER BY 
    u.Reputation DESC 
LIMIT 10;
