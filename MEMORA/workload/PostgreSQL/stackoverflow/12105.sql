
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.BadgeCount AS PostOwnerBadgeCount,
    ps.TotalBountyAmount AS PostBountyAmount,
    us.UserId,
    us.DisplayName,
    us.BadgeCount AS UserBadgeCount,
    us.TotalBountyAmount AS UserTotalBountyAmount
FROM 
    PostStatistics ps
JOIN 
    Users u ON ps.PostId = u.Id 
JOIN 
    UserStatistics us ON u.Id = us.UserId 
ORDER BY 
    ps.CreationDate DESC;
