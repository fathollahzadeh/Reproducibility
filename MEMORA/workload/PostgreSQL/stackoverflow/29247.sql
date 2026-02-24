
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id) AS VoteCount,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id) AS CommentCount
    FROM 
        Users u
), TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUserCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
), RecentActivity AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        p.Title,
        pt.Name AS PostType,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.UserId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    us.DisplayName AS UserName,
    us.Reputation,
    us.PostCount,
    us.VoteCount,
    us.BadgeCount,
    us.CommentCount,
    ts.TagName,
    ts.PostCount AS TagPostCount,
    ts.UniqueUserCount,
    ts.TotalViews,
    ts.AverageScore,
    ra.PostId,
    ra.Title,
    ra.PostType,
    ra.Comment AS RecentActivityComment
FROM 
    UserStats us
LEFT JOIN 
    TagStats ts ON us.UserId = (SELECT OwnerUserId FROM Posts ORDER BY RANDOM() LIMIT 1) 
LEFT JOIN 
    RecentActivity ra ON us.UserId = ra.UserId
WHERE 
    ra.rn = 1
ORDER BY 
    us.Reputation DESC, 
    ts.PostCount DESC
LIMIT 100;
