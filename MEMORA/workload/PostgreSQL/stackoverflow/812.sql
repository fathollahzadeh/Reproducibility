
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN u.LastAccessDate < CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days' THEN 'Inactive'
            ELSE 'Active'
        END AS UserStatus
    FROM 
        Users u
), 
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags 
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag_name ON true
    JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        p.Id
)
SELECT
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    CASE 
        WHEN ur.UserStatus = 'Active' AND rp.CommentCount > 5 THEN 'High Engagement'
        WHEN ur.UserStatus = 'Inactive' AND rp.CommentCount <= 5 THEN 'Low Engagement'
        ELSE 'Moderate Engagement'
    END AS EngagementLevel,
    ur.UserStatus,
    pt.Tags
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.Id
LEFT JOIN 
    PostTags pt ON rp.Id = pt.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC
LIMIT 50;
