
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalEdits,
        COUNT(DISTINCT ph.PostId) AS TotalEditedPosts,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11)
    GROUP BY 
        ph.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.TotalUpvotes,
    us.TotalDownvotes,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.TotalViews,
    COALESCE(phs.TotalEdits, 0) AS TotalEdits,
    COALESCE(phs.TotalEditedPosts, 0) AS TotalEditedPosts,
    phs.LastEditDate
FROM 
    UserStats us
LEFT JOIN 
    PostHistoryStats phs ON us.UserId = phs.UserId
ORDER BY 
    us.TotalPosts DESC, us.TotalUpvotes DESC
FETCH FIRST 50 ROWS ONLY;
