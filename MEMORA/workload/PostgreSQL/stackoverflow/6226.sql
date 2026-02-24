WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY 
            PostId) c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        mu.UserId,
        mu.PostCount,
        mu.TotalViews,
        mu.TotalComments
    FROM 
        RankedPosts rp
    JOIN 
        MostActiveUsers mu ON rp.OwnerDisplayName = mu.DisplayName
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tpd.PostId,
    tpd.Title,
    tpd.CreationDate,
    tpd.Score,
    tpd.ViewCount,
    tpd.OwnerDisplayName,
    tpd.PostCount AS ActiveUserPostCount,
    tpd.TotalViews AS ActiveUserTotalViews,
    tpd.TotalComments AS ActiveUserTotalComments
FROM 
    TopPostDetails tpd
ORDER BY 
    tpd.Score DESC, tpd.CreationDate DESC;