
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserRank,
        p.OwnerUserId,
        p.LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId, p.LastActivityDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    r.Title,
    r.Score,
    r.ViewCount,
    r.CommentCount,
    r.VoteCount,
    u.DisplayName AS Owner,
    u.Reputation AS OwnerReputation,
    u.PostCount AS OwnerPostCount,
    u.TotalScore AS OwnerTotalScore
FROM 
    RankedPosts r
JOIN 
    UserReputation u ON r.OwnerUserId = u.UserId
WHERE 
    r.UserRank = 1
ORDER BY 
    r.Score DESC, r.ViewCount DESC
LIMIT 10;
