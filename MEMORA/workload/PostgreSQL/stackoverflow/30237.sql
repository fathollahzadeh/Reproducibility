WITH RECURSIVE UserReputation AS (
    
    SELECT 
        u.Id AS UserId,
        u.Reputation + COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1000 WHEN b.Class = 2 THEN 500 WHEN b.Class = 3 THEN 100 END), 0) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostActivity AS (
    
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(c.Id) AS CommentCount,
        SUM(p.FavoriteCount) AS TotalFavorites
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    GROUP BY 
        p.OwnerUserId
),
UserStats AS (
    
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ur.TotalReputation, 0) AS Reputation,
        COALESCE(pa.TotalPosts, 0) AS PostCount,
        COALESCE(pa.TotalViews, 0) AS ViewCount,
        COALESCE(pa.TotalScore, 0) AS Score,
        COALESCE(pa.CommentCount, 0) AS Comments,
        COALESCE(pa.TotalFavorites, 0) AS Favorites
    FROM 
        Users u
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.UserId
    LEFT JOIN 
        PostActivity pa ON u.Id = pa.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.ViewCount,
    us.Score,
    us.Comments,
    us.Favorites,
    CASE 
        WHEN us.PostCount > 50 THEN 'Expert'
        WHEN us.PostCount BETWEEN 20 AND 50 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserTier,
    (
        SELECT 
            STRING_AGG(DISTINCT t.TagName, ', ') 
        FROM 
            Posts p 
        JOIN 
            Tags t ON p.Tags LIKE '%' || t.TagName || '%'
        WHERE 
            p.OwnerUserId = us.UserId
    ) AS PopularTags
FROM 
    UserStats us
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, us.PostCount DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;