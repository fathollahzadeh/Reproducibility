WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(bs.BadgeCount, 0) AS BadgeCount,
        COALESCE(bs.GoldCount, 0) AS GoldCount,
        COALESCE(bs.SilverCount, 0) AS SilverCount,
        COALESCE(bs.BronzeCount, 0) AS BronzeCount,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.AvgScore, 0) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        UserBadges bs ON u.Id = bs.UserId
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        COUNT(DISTINCT ph.PostId) AS ClosedPostCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.UserId
),
FinalStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.BadgeCount,
        ua.GoldCount,
        ua.SilverCount,
        ua.BronzeCount,
        ua.TotalViews,
        ua.AvgScore,
        COALESCE(cp.ClosedPostCount, 0) AS ClosedPostCount,
        CASE 
            WHEN ua.TotalViews > 10000 THEN 'Popular Contributor'
            WHEN ua.BadgeCount > 5 THEN 'Active Contributor'
            ELSE 'New Contributor'
        END AS ContributorStatus
    FROM 
        UserActivity ua
    LEFT JOIN 
        ClosedPosts cp ON ua.UserId = cp.UserId
)
SELECT 
    DisplayName,
    PostCount,
    BadgeCount,
    GoldCount,
    SilverCount,
    BronzeCount,
    TotalViews,
    AvgScore,
    ClosedPostCount,
    ContributorStatus
FROM 
    FinalStats
WHERE 
    (PostCount > 5 OR ClosedPostCount > 0)
    AND (AvgScore IS NULL OR AvgScore >= 1)
ORDER BY 
    TotalViews DESC, 
    BadgeCount DESC
LIMIT 10;