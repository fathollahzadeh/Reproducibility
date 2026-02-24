WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '5 years'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(c.Id) AS CommentCount,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 AND
        u.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        u.Id
    HAVING 
        AVG(COALESCE(p.ViewCount, 0)) > 50
),
RightJoinPosts AS (
    SELECT 
        p.Id,
        pt.Name AS PostTypeName,
        COALESCE(ph.Comment, 'No comments') AS HistoryComment
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    RIGHT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
),
FinalOutput AS (
    SELECT 
        up.UserId,
        RANK() OVER (ORDER BY up.TotalBounty DESC) AS UserRank,
        up.TotalBounty,
        up.CommentCount,
        up.AvgViewCount,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rj.PostTypeName,
        rj.HistoryComment
    FROM 
        UserActivity up
    JOIN 
        RankedPosts rp ON up.CommentCount > 5 AND rp.Rank <= 3
    LEFT JOIN 
        RightJoinPosts rj ON rp.PostId = rj.Id
)
SELECT 
    *,
    CASE 
        WHEN TotalBounty > 1000 THEN 'High Contributor'
        WHEN TotalBounty BETWEEN 500 AND 1000 THEN 'Moderate Contributor'
        ELSE 'Low Contributor'
    END AS ContributorLevel,
    CASE 
        WHEN ViewCount IS NULL THEN 'Unviewed'
        WHEN ViewCount > 1000 THEN 'Popular'
        ELSE 'Normal'
    END AS ViewStatus
FROM 
    FinalOutput
ORDER BY 
    UserRank, Score DESC
LIMIT 50;