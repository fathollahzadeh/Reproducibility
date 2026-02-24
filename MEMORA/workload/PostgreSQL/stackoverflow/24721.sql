WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score IS NULL THEN 0 ELSE c.Score END) AS TotalScore
    FROM 
        Comments c 
    GROUP BY 
        c.PostId
),
PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL (
            SELECT 
                t.TagName 
            FROM 
                UNNEST(string_to_array(p.Tags, '>')) AS tags_array(tag) 
            JOIN 
                Tags t ON t.TagName = tags_array.tag
        ) t ON true
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ur.UserId,
    ur.Reputation,
    ur.BadgeCount,
    tc.CommentCount,
    tc.TotalScore,
    pt.TagsList
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON ur.UserId = (
        SELECT 
            p.OwnerUserId 
        FROM 
            Posts p 
        WHERE 
            p.Id = rp.PostId
    )
LEFT JOIN 
    TopComments tc ON tc.PostId = rp.PostId
LEFT JOIN 
    PostsWithTags pt ON pt.PostId = rp.PostId
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC,
    ur.Reputation DESC
LIMIT 100
OFFSET 0;