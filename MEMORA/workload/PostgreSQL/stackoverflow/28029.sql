WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
    ORDER BY 
        p.CreationDate DESC
    LIMIT 10
),
PostStats AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        ARRAY_LENGTH(rp.Tags, 1) AS TagCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount
    FROM 
        RankedPosts rp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.TagCount,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.Score * 1.0 / NULLIF(ps.TagCount, 0) AS ScorePerTag,
    ps.Score * 1.0 / NULLIF(ps.CommentCount, 0) AS ScorePerComment,
    ps.ViewCount * 1.0 / NULLIF(ps.CommentCount, 0) AS ViewPerComment
FROM 
    PostStats ps
WHERE 
    ps.Score > 0 
ORDER BY 
    ScorePerTag DESC, ScorePerComment DESC;