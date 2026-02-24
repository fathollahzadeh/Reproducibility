WITH UserMetrics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
ActiveUsers AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.Reputation,
        ROW_NUMBER() OVER (ORDER BY um.Reputation DESC) AS ReputationRank,
        DENSE_RANK() OVER (PARTITION BY CASE 
                                            WHEN um.QuestionCount > 0 THEN 'Active Questions' 
                                            WHEN um.AnswerCount > 0 THEN 'Active Answers' 
                                            ELSE 'Inactive' 
                                        END 
                                        ORDER BY um.PostCount DESC) AS ActivityRank
    FROM UserMetrics um
    WHERE um.LastPostDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
),
BadgeData AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
FinalMetrics AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        au.Reputation,
        au.ReputationRank,
        au.ActivityRank,
        COALESCE(bd.BadgeCount, 0) AS BadgeCount,
        COALESCE(bd.GoldBadgeCount, 0) AS GoldBadgeCount,
        COALESCE(bd.SilverBadgeCount, 0) AS SilverBadgeCount,
        COALESCE(bd.BronzeBadgeCount, 0) AS BronzeBadgeCount
    FROM ActiveUsers au
    LEFT JOIN BadgeData bd ON au.UserId = bd.UserId
)
SELECT
    f.DisplayName,
    f.Reputation,
    f.ReputationRank,
    f.ActivityRank,
    f.BadgeCount,
    f.GoldBadgeCount,
    f.SilverBadgeCount,
    f.BronzeBadgeCount
FROM FinalMetrics f
WHERE f.ReputationRank <= 10
ORDER BY f.Reputation DESC, f.ActivityRank ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;