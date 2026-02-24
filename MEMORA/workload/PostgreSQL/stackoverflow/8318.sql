
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2021-01-01'
        AND p.Score > 0
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
TagStats AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS tagList ON TRUE
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH ' ' FROM tagList) AND t.Count > 10
    GROUP BY 
        p.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpvoteCount,
    ts.Tags
FROM 
    PostStats ps
LEFT JOIN 
    TagStats ts ON ps.PostId = ts.PostId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
