
WITH RecursiveTagCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' )  
    GROUP BY 
        t.Id, t.TagName
),
UserReputationHistory AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        RANK() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
ClosedPostsDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS CloseDate,
        ph.UserDisplayName AS ClosedBy,
        STRING_AGG(ph.Comment, ', ') AS CloseReasons
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        p.Id, p.Title, ph.CreationDate, ph.UserDisplayName
),
UserBadgeCount AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ut.Id AS UserId,
    ut.DisplayName,
    COALESCE(rh.Reputation, 0) AS LatestReputation,
    COALESCE(ubc.BadgeCount, 0) AS TotalBadges,
    COALESCE(ubc.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubc.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubc.BronzeBadges, 0) AS BronzeBadges,
    tg.TagName,
    tg.PostCount,
    p.CloseDate,
    p.ClosedBy, 
    p.CloseReasons,
    DENSE_RANK() OVER (PARTITION BY tg.TagId ORDER BY tg.PostCount DESC) AS TopPostRank
FROM 
    Users ut
LEFT JOIN 
    UserReputationHistory rh ON ut.Id = rh.UserId AND rh.Rank = 1
LEFT JOIN 
    UserBadgeCount ubc ON ubc.UserId = ut.Id
LEFT JOIN 
    RecursiveTagCounts tg ON ut.Id = tg.TagId
LEFT JOIN 
    ClosedPostsDetails p ON ut.Id = p.PostId 
WHERE 
    ut.Reputation > (SELECT AVG(Reputation) FROM Users)  
    AND (tg.PostCount IS NULL OR tg.PostCount > 5)  
ORDER BY 
    LatestReputation DESC,
    TotalBadges DESC,
    tg.PostCount DESC;
