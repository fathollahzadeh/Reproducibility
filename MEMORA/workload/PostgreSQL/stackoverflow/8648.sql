
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank,
        p.OwnerUserId  -- Added OwnerUserId to the GROUP BY clause
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId  -- Added necessary columns to GROUP BY
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        CommentCount, 
        UpvoteCount, 
        DownvoteCount,
        OwnerUserId  -- Added OwnerUserId to TopPosts to use in the final SELECT
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    tp.*,
    u.DisplayName AS OwnerDisplayName,
    b.Name AS BadgeName,
    CASE 
        WHEN tp.UpvoteCount > tp.DownvoteCount THEN 'Positive'
        ELSE 'Negative or Neutral'
    END AS Sentiment
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
