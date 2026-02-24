WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
FinalStats AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        ubs.BadgeCount,
        ubs.GoldBadges,
        ubs.SilverBadges,
        ubs.BronzeBadges,
        ps.PostCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.WikiCount,
        ps.TotalScore,
        ps.AvgViewCount
    FROM 
        Users u
    JOIN 
        UserBadgeStats ubs ON u.Id = ubs.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    WHERE 
        u.Reputation > 100 AND
        u.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    DisplayName,
    Reputation,
    LastAccessDate,
    (Views + UpVotes - DownVotes) AS EngagementScore,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    QuestionCount,
    AnswerCount,
    WikiCount,
    TotalScore,
    AvgViewCount
FROM 
    FinalStats
ORDER BY 
    EngagementScore DESC, Reputation DESC
LIMIT 100;