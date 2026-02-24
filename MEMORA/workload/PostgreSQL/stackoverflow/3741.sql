WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.Upvotes,
    ur.Downvotes,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    tt.TagName AS PopularTag
FROM 
    UserReputation ur
LEFT JOIN 
    RecentPosts rp ON ur.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    TopTags tt ON tt.PostCount > 0
WHERE 
    ur.Reputation > 1000 AND ur.Reputation < 10000
    OR (ur.Upvotes IS NOT NULL AND ur.Upvotes > 50)
ORDER BY 
    ur.Reputation DESC
LIMIT 50;