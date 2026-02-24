WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        MAX(b.Date) AS LastBadgeDate
    FROM
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ClosedPostHistory AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS ClosedPostCount,
        STRING_AGG(p.Title, ', ') AS ClosedPostTitles,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.AvgScore, 0) AS AvgScore,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(cs.ClosedPostCount, 0) AS ClosedPostCount,
        COALESCE(cs.ClosedPostTitles, 'None') AS ClosedPostTitles,
        COALESCE(cs.LastClosedDate, '1900-01-01') AS LastClosedDate,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        ClosedPostHistory cs ON u.Id = cs.UserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    AvgScore,
    TotalViews,
    ClosedPostCount,
    ClosedPostTitles,
    LastClosedDate,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    UserPerformance
WHERE 
    (ClosedPostCount > 0 OR BadgeCount > 0)
ORDER BY 
    Reputation DESC,
    PostCount DESC,
    TotalViews DESC;
