
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
),
PostWithUserReputation AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.Score,
        ur.Reputation AS UserReputation,
        ur.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.UserId
)
SELECT 
    pw.UserReputation,
    pw.BadgeCount,
    COUNT(*) FILTER (WHERE pw.Score > 10) AS HighScoringPosts,
    ARRAY_AGG(pw.Title) AS PostTitles
FROM 
    PostWithUserReputation pw
GROUP BY 
    pw.UserReputation, pw.BadgeCount
HAVING 
    COUNT(*) > 5
ORDER BY 
    pw.UserReputation DESC
LIMIT 10;
