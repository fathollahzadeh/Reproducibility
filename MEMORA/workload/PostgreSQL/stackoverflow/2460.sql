WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        AVG(COALESCE(v.BountyAmount, 0)) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    GROUP BY 
        u.Id
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        c.PostId
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    COALESCE(rc.CommentCount, 0) AS CommentCount,
    ups.UserId,
    ups.PostCount,
    ups.TotalBounty,
    ups.AvgBounty
FROM 
    RankedPosts pp
JOIN 
    UserPostStats ups ON pp.PostId = ups.UserId  
LEFT JOIN 
    RecentComments rc ON pp.PostId = rc.PostId
WHERE 
    pp.Rank <= 5
ORDER BY 
    pp.Score DESC, pp.PostId ASC
FETCH FIRST 10 ROWS ONLY;