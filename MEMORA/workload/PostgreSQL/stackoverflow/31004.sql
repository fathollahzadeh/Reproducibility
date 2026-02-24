WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.PostId) AS QuestionCount,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.Score) AS AverageScore,
        MAX(rp.CreationDate) AS LastQuestionDate
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeStatistics AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        COALESCE(ups.QuestionCount, 0) AS QuestionCount,
        COALESCE(ups.TotalScore, 0) AS TotalScore,
        COALESCE(ups.TotalViews, 0) AS TotalViews,
        COALESCE(ups.AverageScore, 0.0) AS AverageScore,
        COALESCE(bs.BadgeCount, 0) AS BadgeCount,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
        DENSE_RANK() OVER (ORDER BY COALESCE(ups.QuestionCount, 0) DESC, COALESCE(ups.TotalScore, 0) DESC) AS UserRank
    FROM 
        UserPostStats ups
    FULL OUTER JOIN 
        BadgeStatistics bs ON ups.UserId = bs.UserId
),
TopUsers AS (
    SELECT *
    FROM CombinedStats
    WHERE UserRank <= 10
)
SELECT 
    cu.DisplayName,
    cu.QuestionCount,
    cu.TotalScore,
    cu.TotalViews,
    cu.AverageScore,
    cu.BadgeCount,
    cu.GoldBadges,
    cu.SilverBadges,
    cu.BronzeBadges
FROM 
    TopUsers cu
ORDER BY 
    cu.QuestionCount DESC, 
    cu.TotalScore DESC;