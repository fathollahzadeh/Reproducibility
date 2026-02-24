
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Id, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        COALESCE(pc.comment_count, 0) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS comment_count 
         FROM Comments 
         GROUP BY PostId) pc ON p.Id = pc.PostId
    ORDER BY 
        p.Score DESC
    LIMIT 10
),
PostHistorySummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS TotalEdits,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalScore,
    ua.TotalComments,
    tp.PostId,
    tp.Title AS TopPostTitle,
    tp.CreationDate AS PostCreationDate,
    tp.Score AS PostScore,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.CommentCount,
    phs.TotalEdits,
    phs.LastEditDate
FROM 
    UserActivity ua
JOIN 
    TopPosts tp ON ua.DisplayName = tp.OwnerDisplayName
JOIN 
    PostHistorySummary phs ON tp.PostId = phs.PostId
ORDER BY 
    ua.TotalScore DESC, 
    tp.Score DESC;
