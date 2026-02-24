
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        LATERAL (SELECT unnest(string_to_array(substring(p.Tags FROM 2 FOR length(p.Tags) - 2), '><')) AS tag) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
    u.Upvotes,
    u.Downvotes,
    pt.Tags,
    CASE
        WHEN p.Score >= 10 THEN 'High Score'
        WHEN p.Score >= 5 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    RankedPosts p
LEFT JOIN 
    UserStats u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostTags pt ON p.PostId = pt.PostId
WHERE 
    p.rn = 1
  AND 
    (u.Upvotes - u.Downvotes) > 0
ORDER BY 
    p.Score DESC, p.CreationDate ASC
LIMIT 100;
