
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopTags AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY TagName
    ORDER BY TagCount DESC
    LIMIT 10
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount,
        MIN(ph.CreationDate) AS FirstEdit,
        MAX(ph.CreationDate) AS LastEdit
    FROM PostHistory ph 
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY ph.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.PositivePosts,
    us.NegativePosts,
    us.TotalBounties,
    COALESCE(ph.EditCount, 0) AS EditCount,
    ph.FirstEdit,
    ph.LastEdit,
    tt.TagName
FROM UserStatistics us
LEFT JOIN PostHistoryStats ph ON us.UserId = ph.UserId
CROSS JOIN TopTags tt
ORDER BY us.Reputation DESC, us.TotalPosts DESC;
