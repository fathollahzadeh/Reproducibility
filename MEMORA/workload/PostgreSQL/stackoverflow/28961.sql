
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
TopBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    b.BadgeCount,
    b.BadgeNames,
    pp.PostId,
    pp.Title,
    pp.Body,
    pp.Tags,
    pp.CreationDate,
    pp.ViewCount,
    pp.Score,
    COALESCE(pc.CommentCount, 0) AS CommentCount
FROM 
    UserReputation u
JOIN 
    RankedPosts pp ON u.UserId = pp.OwnerUserId
LEFT JOIN 
    TopBadges b ON u.UserId = b.UserId
LEFT JOIN 
    PostComments pc ON pp.PostId = pc.PostId
WHERE 
    pp.RankScore <= 5 
ORDER BY 
    u.Reputation DESC,
    pp.Score DESC;
