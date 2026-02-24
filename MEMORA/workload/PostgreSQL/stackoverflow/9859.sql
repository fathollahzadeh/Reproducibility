
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        AnswerCount, 
        CommentCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostStats AS (
    SELECT 
        tp.Title, 
        tp.ViewCount, 
        tp.AnswerCount, 
        tp.CommentCount, 
        COUNT(c.Id) AS TotalComments, 
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        tp.Title, tp.ViewCount, tp.AnswerCount, tp.CommentCount
)
SELECT 
    ts.Title,
    ts.ViewCount,
    ts.AnswerCount,
    ts.CommentCount,
    ts.TotalComments,
    ts.TotalBounties,
    (CAST(ts.TotalComments AS decimal(10,2)) / NULLIF(ts.ViewCount, 0) * 100) AS CommentEngagementRate,
    CASE 
        WHEN ts.TotalBounties > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS HasBounty
FROM 
    PostStats ts
ORDER BY 
    ts.ViewCount DESC, ts.AnswerCount DESC;
