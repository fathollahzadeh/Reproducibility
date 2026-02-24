
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5
),
TaggedPosts AS (
    SELECT 
        hp.*,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        HighScorePosts hp
    JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(hp.Body, '<tag>')) AS TagName 
        ) t ON true
    GROUP BY 
        hp.PostId, hp.Title, hp.Body, hp.CreationDate, hp.ViewCount, hp.Score, hp.OwnerDisplayName, hp.CommentCount
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.CreationDate,
    tp.Tags,
    COALESCE((
        SELECT 
            COUNT(*)
        FROM 
            Votes v
        WHERE 
            v.PostId = tp.PostId AND v.VoteTypeId = 2 
    ), 0) AS UpVotes
FROM 
    TaggedPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
