
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rs.PostId,
    rs.Title,
    rs.CreationDate,
    rs.ViewCount,
    rs.Score,
    rs.AnswerCount,
    rs.CommentCount,
    us.UserId,
    us.DisplayName AS UserDisplayName,
    us.PostCount,
    us.BadgeCount,
    us.TotalBounties
FROM 
    RankedPosts rs
JOIN 
    UserStatistics us ON rs.OwnerUserId = us.UserId
WHERE 
    rs.Rank <= 5
ORDER BY 
    rs.Score DESC, rs.ViewCount DESC;
