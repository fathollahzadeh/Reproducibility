
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.FavoriteCount, 0) AS FavoriteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopRatedPosts AS (
    SELECT 
        r.* 
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 5 
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 2) AS TotalUpvotes,  
        COUNT(*) FILTER (WHERE v.VoteTypeId = 3) AS TotalDownvotes, 
        COUNT(DISTINCT c.Id) AS TotalComments 
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.OwnerDisplayName,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    ps.TotalComments,
    t.Tags
FROM 
    TopRatedPosts t
JOIN 
    PostStatistics ps ON t.PostId = ps.PostId
ORDER BY 
    t.Score DESC, t.CreationDate DESC;
