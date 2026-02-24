
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, u.DisplayName, p.OwnerUserId
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN r.Rank = 1 THEN 1 ELSE 0 END) AS TopPostsCount,
        SUM(r.ViewCount) AS TotalViews,
        SUM(r.Score) AS TotalScore,
        SUM(r.CommentCount) AS TotalComments,
        SUM(r.VoteCount) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.TopPostsCount,
    us.TotalViews,
    us.TotalScore,
    us.TotalComments,
    us.TotalVotes,
    ROW_NUMBER() OVER (ORDER BY us.TotalViews DESC) AS UserRank
FROM 
    UserStats us
WHERE 
    us.TotalViews > 0
ORDER BY 
    us.TotalViews DESC
LIMIT 10;
