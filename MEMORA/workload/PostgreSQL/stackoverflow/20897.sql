WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
HighScorePosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerUserId,
        r.Rank,
        u.Reputation
    FROM 
        RankedPosts r
    JOIN 
        UserReputation u ON r.OwnerUserId = u.UserId
    WHERE 
        r.Score > (SELECT AVG(Score) FROM Posts) 
        AND r.Rank <= 2
)
SELECT 
    p.Title,
    u.DisplayName,
    COALESCE(b.Class, 0) AS BadgeClass,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    SUM(v.BountyAmount) AS TotalBounty,
    COUNT(DISTINCT c.Id) AS CommentCount,
    CASE 
        WHEN COUNT(DISTINCT v.UserId) > 0 THEN true 
        ELSE false 
    END AS HasVotes
FROM 
    HighScorePosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id 
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
LEFT JOIN 
    Comments c ON p.PostId = c.PostId
LEFT JOIN 
    Votes v ON p.PostId = v.PostId AND v.VoteTypeId IN (2, 3) 
GROUP BY 
    p.PostId, p.Title, u.DisplayName, b.Class, b.Name
HAVING 
    COUNT(DISTINCT c.Id) > 0 OR SUM(v.BountyAmount) > 0
ORDER BY 
    SUM(v.BountyAmount) DESC, p.Title;