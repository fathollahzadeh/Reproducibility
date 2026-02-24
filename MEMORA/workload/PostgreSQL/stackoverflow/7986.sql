
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount,
        RANK() OVER (ORDER BY p.Score DESC) AS RankScore,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS RankViews
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UniqueVoterCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 100 OR rp.RankViews <= 100
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UniqueVoterCount
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.CommentCount DESC, 
    fp.UniqueVoterCount DESC;
