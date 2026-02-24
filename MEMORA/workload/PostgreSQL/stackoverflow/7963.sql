
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.PostTypeId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopContributors AS (
    SELECT
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.QuestionsCount,
        us.AnswersCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        COUNT(DISTINCT ph.Id) AS PostHistoryCount,
        AVG(COALESCE(pt.ViewCount, 0)) AS AvgPostViews
    FROM 
        UserStats us
    LEFT JOIN 
        Posts p ON us.UserId = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        RankedPosts pt ON p.Id = pt.PostId
    GROUP BY 
        us.UserId, us.DisplayName, us.TotalPosts, us.QuestionsCount, us.AnswersCount, us.GoldBadges, us.SilverBadges, us.BronzeBadges
)
SELECT 
    tc.DisplayName,
    tc.TotalPosts,
    tc.QuestionsCount,
    tc.AnswersCount,
    tc.GoldBadges,
    tc.SilverBadges,
    tc.BronzeBadges,
    tc.PostHistoryCount,
    tc.AvgPostViews
FROM 
    TopContributors tc
WHERE 
    tc.TotalPosts > 10 
ORDER BY 
    tc.TotalPosts DESC, 
    tc.AvgPostViews DESC;
