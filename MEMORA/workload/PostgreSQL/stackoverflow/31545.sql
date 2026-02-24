
WITH RECURSIVE UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class,
        b.Date,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(p.Score) AS TotalPostScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    GROUP BY 
        u.Id, u.DisplayName
),
UserHistory AS (
    SELECT 
        uh.UserId,
        COUNT(ph.Id) AS TotalEdits,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        UserBadges uh
    LEFT JOIN 
        PostHistory ph ON uh.UserId = ph.UserId
    GROUP BY 
        uh.UserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalPostScore,
    ua.TotalBounty,
    COALESCE(uh.TotalEdits, 0) AS TotalEdits,
    uh.LastEditDate,
    ub.BadgeName,
    ub.Class,
    ub.Date AS BadgeDate
FROM 
    UserActivity ua
LEFT JOIN 
    UserHistory uh ON ua.UserId = uh.UserId
LEFT JOIN 
    UserBadges ub ON ua.UserId = ub.UserId AND ub.BadgeRank = 1
WHERE 
    ua.TotalPosts > 5 
ORDER BY 
    ua.TotalPostScore DESC,
    ua.DisplayName;
