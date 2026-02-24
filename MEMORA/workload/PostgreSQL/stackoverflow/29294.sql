
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        CONCAT(u.DisplayName, ' (Reputation: ', u.Reputation, ')') AS UserInfo,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ActivePosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
PostHistoryAnalysis AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS Edits,
        COUNT(DISTINCT ph.PostId) AS EditedPosts
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        ph.UserId
),
CombinedData AS (
    SELECT 
        ubc.UserId,
        ubc.UserInfo,
        ubc.BadgeCount,
        ubc.GoldBadges,
        ubc.SilverBadges,
        ubc.BronzeBadges,
        ap.TotalPosts,
        ap.Questions,
        ap.Answers,
        ap.PopularPosts,
        pha.Edits,
        pha.EditedPosts
    FROM 
        UserBadgeCounts ubc
    LEFT JOIN 
        ActivePosts ap ON ubc.UserId = ap.OwnerUserId
    LEFT JOIN 
        PostHistoryAnalysis pha ON ubc.UserId = pha.UserId
)
SELECT 
    UserId,
    UserInfo,
    COALESCE(BadgeCount, 0) AS BadgeCount,
    COALESCE(GoldBadges, 0) AS GoldBadges,
    COALESCE(SilverBadges, 0) AS SilverBadges,
    COALESCE(BronzeBadges, 0) AS BronzeBadges,
    COALESCE(TotalPosts, 0) AS TotalPosts,
    COALESCE(Questions, 0) AS Questions,
    COALESCE(Answers, 0) AS Answers,
    COALESCE(PopularPosts, 0) AS PopularPosts,
    COALESCE(Edits, 0) AS Edits,
    COALESCE(EditedPosts, 0) AS EditedPosts
FROM 
    CombinedData
ORDER BY 
    BadgeCount DESC, UserInfo DESC;
