
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.Score, u.DisplayName
),
RecentActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS RecentPostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.TagCount,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    ra.UsersEngagement,
    ra.Reputation AS OwnerReputation,
    rp.CommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT 
         UserId,
         COUNT(*) AS UsersEngagement,
         AVG(Reputation) AS Reputation
     FROM 
         RecentActiveUsers
     GROUP BY 
         UserId) ra ON rp.OwnerPostRank <= 5
WHERE 
    rp.TagCount > 0
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 10;
