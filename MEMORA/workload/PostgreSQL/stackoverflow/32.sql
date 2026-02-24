
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pr.UserRank
    FROM 
        Posts p
    JOIN (
        SELECT 
            p.Id,
            ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS UserRank
        FROM 
            Posts p
        WHERE 
            p.CreationDate >= CURRENT_DATE - INTERVAL '30 DAY'
    ) pr ON p.Id = pr.Id
)
SELECT 
    ua.DisplayName,
    COUNT(DISTINCT pp.PostId) AS PopularPostCount,
    SUM(pp.ViewCount) AS TotalPopularViews,
    (SELECT COUNT(DISTINCT b.Id) FROM Badges b WHERE b.UserId = ua.UserId) AS BadgeCount
FROM 
    UserActivity ua
LEFT JOIN 
    PopularPosts pp ON ua.UserId = pp.UserRank
GROUP BY 
    ua.UserId, ua.DisplayName
HAVING 
    COUNT(DISTINCT pp.PostId) > 0 
ORDER BY 
    TotalPopularViews DESC
LIMIT 10;
