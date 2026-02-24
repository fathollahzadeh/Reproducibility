
WITH RankedUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users
    WHERE 
        Reputation > 100
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(AVG(v.BountyAmount), 0) AS AverageBounty,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        pm.*,
        RANK() OVER (ORDER BY pm.ViewCount DESC) AS PostRank
    FROM 
        PostMetrics pm
    WHERE 
        pm.CommentCount > 5
)
SELECT 
    ru.DisplayName AS TopUser,
    tp.Title AS TopPost,
    tp.ViewCount,
    tp.AverageBounty,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    tp.CloseCount
FROM 
    RankedUsers ru
JOIN 
    TopPosts tp ON ru.Id = tp.PostId
WHERE 
    tp.PostRank <= 10
ORDER BY 
    ru.Reputation DESC, tp.ViewCount DESC;
