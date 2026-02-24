WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankView
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
),

PostStatistics AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        CASE 
            WHEN RankScore = 1 THEN 'Top Score'
            WHEN RankView = 1 THEN 'Top View'
            ELSE 'Regular'
        END AS PostRank
    FROM 
        RankedPosts
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.PostRank,
    ue.DisplayName AS UserDisplayName,
    ue.TotalUpvotes,
    ue.TotalDownvotes,
    ue.TotalComments
FROM 
    PostStatistics ps
JOIN 
    Posts p ON ps.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserEngagement ue ON u.Id = ue.UserId
WHERE 
    ps.PostRank IN ('Top Score', 'Top View')
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;