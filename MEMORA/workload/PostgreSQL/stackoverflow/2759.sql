WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        pv.VoteScore,
        ROW_NUMBER() OVER (ORDER BY COALESCE(pv.VoteScore, 0) DESC, rp.Score DESC) AS OverallRank
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    COALESCE(tp.VoteScore, 0) AS VoteScore,
    CASE 
        WHEN tp.OverallRank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS RankCategory
FROM 
    TopPosts tp
WHERE 
    tp.CommentCount > 0 OR tp.VoteScore IS NOT NULL
ORDER BY 
    tp.OverallRank;