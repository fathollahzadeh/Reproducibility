
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalChanges,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (6, 4) THEN 1 ELSE 0 END) AS TagTitleEditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
),
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.Questions,
        ups.Answers,
        ups.Wikis,
        ups.TotalScore,
        ups.TotalViews,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        phs.TotalChanges,
        phs.CloseReopenCount,
        phs.TagTitleEditCount
    FROM 
        UserPostStats ups
    LEFT JOIN 
        UserBadges ub ON ups.UserId = ub.UserId
    LEFT JOIN 
        PostHistorySummary phs ON ups.UserId = phs.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    Wikis,
    TotalScore,
    TotalViews,
    COALESCE(GoldBadges, 0) AS GoldBadges,
    COALESCE(SilverBadges, 0) AS SilverBadges,
    COALESCE(BronzeBadges, 0) AS BronzeBadges,
    COALESCE(TotalChanges, 0) AS TotalChanges,
    COALESCE(CloseReopenCount, 0) AS CloseReopenCount,
    COALESCE(TagTitleEditCount, 0) AS TagTitleEditCount
FROM 
    CombinedStats
ORDER BY 
    TotalScore DESC, TotalPosts DESC;
