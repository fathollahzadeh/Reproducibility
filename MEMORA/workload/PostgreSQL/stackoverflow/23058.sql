WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(NULLIF(AboutMe, ''), 'No information provided') AS UserInfo
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        CreationDate,
        ViewCount,
        OwnerUserId
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
),
PostCommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteNet
    FROM 
        Votes
    GROUP BY 
        PostId
),
FinalResult AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        COALESCE(pcc.CommentCount, 0) AS CommentCount,
        COALESCE(pv.VoteNet, 0) AS NetVotes,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(CASE 
            WHEN tp.ViewCount > 1000 THEN 'Hot' 
            WHEN tp.ViewCount BETWEEN 500 AND 1000 THEN 'Trending'
            ELSE 'New' END, 'Unknown') AS Popularity
    FROM 
        TopPosts tp
    JOIN 
        Users u ON tp.OwnerUserId = u.Id
    LEFT JOIN 
        PostCommentCounts pcc ON tp.PostId = pcc.PostId
    LEFT JOIN 
        PostVotes pv ON tp.PostId = pv.PostId
)
SELECT 
    f.PostId,
    f.Title,
    f.Score,
    f.ViewCount,
    f.CommentCount,
    f.NetVotes,
    f.OwnerDisplayName,
    f.Popularity,
    CASE 
        WHEN f.Score > 100 THEN 'Highly Rated'
        WHEN f.ViewCount < 50 THEN 'Needs Attention'
        ELSE 'Average Performance'
    END AS PerformanceLabel
FROM 
    FinalResult f
ORDER BY 
    f.Score DESC,
    f.ViewCount DESC;