
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS TypeRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
        AND p.Score IS NOT NULL
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score IS NOT NULL THEN c.Score ELSE 0 END) AS TotalCommentScore
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        c.PostId
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 
                 WHEN vt.Name = 'DownMod' THEN -1 
                 ELSE 0 END) AS VoteScore
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
CombinedResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(pc.CommentCount, 0) AS Comments,
        COALESCE(pc.TotalCommentScore, 0) AS TotalCommentScore,
        COALESCE(pv.VoteScore, 0) AS VoteScore,
        rp.ViewCount,
        rp.TypeRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Comments,
    TotalCommentScore,
    VoteScore,
    ViewCount,
    TypeRank,
    CASE 
        WHEN TypeRank = 1 THEN 'Top Post of its Type'
        WHEN Comments > 5 THEN 'Popular Discussion'
        WHEN VoteScore < 0 THEN 'Needs Attention'
        ELSE 'Regular Post'
    END AS PostStatus
FROM 
    CombinedResults
WHERE 
    TypeRank <= 10
ORDER BY 
    TypeRank, ViewCount DESC;
