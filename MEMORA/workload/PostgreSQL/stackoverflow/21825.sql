WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, PostType
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostViews AS (
    SELECT 
        p.Id AS PostId,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
Final AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        ps.TotalViews,
        uc.UserId,
        uc.Reputation,
        uc.BadgeCount,
        uc.TotalBountyAmount,
        pc.CommentCount,
        CASE 
            WHEN uc.Reputation > 1000 THEN 'Top User'
            ELSE 'Regular User'
        END AS UserType,
        CASE 
            WHEN tp.Score IS NULL THEN 'No Score'
            WHEN tp.Score > 0 THEN 'Positive Score'
            ELSE 'Negative Score'
        END AS ScoreType
    FROM 
        TopPosts tp
    LEFT JOIN 
        UserStats uc ON tp.PostId = uc.UserId
    LEFT JOIN 
        PostViews ps ON tp.PostId = ps.PostId
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    *,
    COALESCE(ROUND(((Score + TotalViews + BadgeCount + TotalBountyAmount) / NULLIF(CommentCount, 0)), 2), 0) AS PerformanceMetric
FROM 
    Final
ORDER BY 
    PerformanceMetric DESC;