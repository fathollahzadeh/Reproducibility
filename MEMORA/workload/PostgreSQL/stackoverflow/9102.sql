WITH ranked_users AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        ROW_NUMBER() OVER (ORDER BY u.Views DESC) AS ViewsRank
    FROM Users u
),
active_users AS (
    SELECT 
        ru.UserId,
        ru.DisplayName,
        ru.Reputation,
        ru.Views,
        CASE 
            WHEN ru.ReputationRank <= 10 THEN 'Top Reputation'
            WHEN ru.ViewsRank <= 10 THEN 'Top Views'
            ELSE 'Regular User'
        END AS UserCategory
    FROM ranked_users ru
),
popular_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.Score > 10
)
SELECT 
    au.DisplayName AS UserName,
    au.Reputation,
    au.Views,
    pp.Title AS PopularPostTitle,
    pp.Score AS PostScore,
    pp.ViewCount AS PostViewCount,
    pp.CreationDate AS PostCreationDate,
    pp.OwnerDisplayName AS PostOwner
FROM active_users au
LEFT JOIN popular_posts pp ON au.UserId = pp.OwnerUserId
WHERE au.UserCategory = 'Top Reputation' OR au.UserCategory = 'Top Views'
ORDER BY au.Reputation DESC, pp.Score DESC
LIMIT 50;
