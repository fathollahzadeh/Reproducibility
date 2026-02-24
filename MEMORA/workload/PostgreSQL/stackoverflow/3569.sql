
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        UNNEST(string_to_array(Tags, '>'))
    HAVING 
        COUNT(*) > 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score,
    rp.ViewCount,
    COALESCE(ut.PostsCount, 0) AS UserPostCount,
    pt.TagName,
    pt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserReputation ut ON rp.PostId = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ut.UserId LIMIT 1)
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (SELECT unnest(string_to_array(rp.Title, ' '))) 
WHERE 
    rp.RankScore <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
