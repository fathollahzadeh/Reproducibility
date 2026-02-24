
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopReputation AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserMetrics
),
RecentPostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.Id AS OwnerId,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        h.Name AS HistoryTypeName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes h ON ph.PostHistoryTypeId = h.Id
    WHERE 
        h.Id IN (10, 11) 
)
SELECT 
    tr.DisplayName,
    tr.Reputation,
    um.TotalViews,
    um.TotalPosts,
    rp.PostId,
    rp.Title AS RecentPostTitle,
    rp.ViewCount AS RecentPostViewCount,
    cnt.ClosedPostsCount,
    COALESCE(ROUND(100.0 * cnt.ClosedPostsCount / NULLIF(um.TotalPosts, 0), 2), 0) AS ClosedPostPercentage,
    CASE 
        WHEN um.Reputation > 1000 THEN 'High Reputation User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    TopReputation tr
JOIN 
    UserMetrics um ON tr.UserId = um.UserId
LEFT JOIN 
    RecentPostDetails rp ON tr.UserId = rp.OwnerId AND rp.PostRank = 1
LEFT JOIN (
    SELECT 
        OwnerId,
        COUNT(*) AS ClosedPostsCount
    FROM 
        ClosedPosts
    GROUP BY 
        OwnerId
) cnt ON tr.UserId = cnt.OwnerId
WHERE 
    tr.Rank <= 10
ORDER BY 
    um.Reputation DESC;
