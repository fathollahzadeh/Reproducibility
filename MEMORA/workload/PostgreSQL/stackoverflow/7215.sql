
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 months' AND
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
VoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS Downvotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    COALESCE(vs.Upvotes, 0) AS TotalUpvotes,
    COALESCE(vs.Downvotes, 0) AS TotalDownvotes,
    CASE 
        WHEN tp.Score > 10 THEN 'Popular'
        WHEN tp.Score <= 10 AND tp.Score > 5 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityCategory
FROM 
    TopPosts tp
LEFT JOIN 
    VoteStats vs ON tp.PostId = vs.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
