
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Owner,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        Owner,
        CommentCount,
        BadgeCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 3 
)
SELECT 
    tp.Owner,
    COUNT(tp.PostId) AS TopPostCount,
    AVG(tp.Score) AS AvgScore,
    SUM(tp.ViewCount) AS TotalViews,
    SUM(tp.CommentCount) AS TotalComments,
    SUM(tp.BadgeCount) AS TotalBadges
FROM 
    TopPosts tp
GROUP BY 
    tp.Owner
HAVING 
    AVG(tp.Score) > 10
ORDER BY 
    TotalViews DESC;
