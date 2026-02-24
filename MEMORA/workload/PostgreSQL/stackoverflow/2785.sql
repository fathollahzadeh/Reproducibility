WITH UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswerCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TopPostOwners AS (
    SELECT 
        ps.OwnerUserId,
        ps.QuestionCount,
        ps.AcceptedAnswerCount,
        ps.TotalViews,
        COALESCE(ubc.GoldBadges, 0) AS GoldBadges,
        COALESCE(ubc.SilverBadges, 0) AS SilverBadges,
        COALESCE(ubc.BronzeBadges, 0) AS BronzeBadges,
        RANK() OVER (ORDER BY ps.TotalViews DESC) AS RankByViews
    FROM 
        PostStatistics ps
    LEFT JOIN 
        UserBadgeCounts ubc ON ps.OwnerUserId = ubc.UserId
    WHERE 
        ps.TotalViews > 1000
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.LastActivityDate,
        p.OwnerUserId,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS Status
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    u.DisplayName,
    tp.QuestionCount,
    tp.AcceptedAnswerCount,
    tp.TotalViews,
    tp.GoldBadges,
    tp.SilverBadges,
    tp.BronzeBadges,
    rp.Title,
    rp.Status
FROM 
    TopPostOwners tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    RecentPosts rp ON rp.OwnerUserId = u.Id
WHERE 
    tp.RankByViews <= 10
ORDER BY 
    tp.RankByViews;