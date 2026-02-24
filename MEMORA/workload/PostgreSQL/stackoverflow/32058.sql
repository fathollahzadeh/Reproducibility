
WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
RecentPostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn,
        p.OwnerUserId AS UserId
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
TopUsers AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.Questions,
        ups.Answers,
        ups.TotalScore,
        COALESCE(bc.TotalBadges, 0) AS BadgeCount,
        COALESCE(bc.GoldBadges, 0) AS GoldBadges,
        COALESCE(bc.SilverBadges, 0) AS SilverBadges,
        COALESCE(bc.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserPostStats ups
    LEFT JOIN 
        BadgeCounts bc ON ups.UserId = bc.UserId
    WHERE 
        ups.TotalScore > 100
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.Questions,
    tu.Answers,
    tu.TotalScore,
    tu.BadgeCount,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    rp.Title AS LastPostTitle,
    COALESCE(rp.Comment, 'No recent activity') AS RecentComment,
    rp.CreationDate AS RecentActivityDate
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPostHistory rp ON tu.UserId = rp.UserId AND rp.rn = 1
ORDER BY 
    tu.TotalScore DESC,
    tu.PostCount DESC;
