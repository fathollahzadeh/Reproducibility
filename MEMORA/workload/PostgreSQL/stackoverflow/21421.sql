
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2021-01-01' 
        AND (p.Title IS NOT NULL AND p.Title <> '') 
        AND (p.Score > 0 OR p.ViewCount > 100)
),
RecentVotes AS (
    SELECT 
        v.PostId, 
        v.VoteTypeId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate > '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days'
    GROUP BY 
        v.PostId, 
        v.VoteTypeId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '><')) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag)
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    pt.Tags,
    COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
    CASE WHEN rp.ViewCount > 1000 THEN 'Popular' ELSE 'Normal' END AS Popularity,
    CASE WHEN rp.Score > 50 THEN 'Highly Rated' ELSE 'Moderately Rated' END AS RatingStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId AND rv.VoteTypeId = 2 
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.rn = 1 
    AND rp.ViewCount < COALESCE((SELECT AVG(ViewCount) FROM Posts), 0) * 1.5 
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
