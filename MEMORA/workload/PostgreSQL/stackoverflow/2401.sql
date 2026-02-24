WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
), BadgeStats AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
), CombinedStats AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        PostCount,
        TotalBounty,
        Upvotes,
        Downvotes,
        COALESCE(BS.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BS.BronzeBadges, 0) AS BronzeBadges
    FROM UserActivity UA
    LEFT JOIN BadgeStats BS ON UA.UserId = BS.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalBounty,
    Upvotes,
    Downvotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    RANK() OVER (ORDER BY PostCount DESC) AS ActivityRank,
    ROW_NUMBER() OVER (PARTITION BY GoldBadges ORDER BY TotalBounty DESC) AS BountyRankPerBadge
FROM CombinedStats
WHERE PostCount > 5
  AND (Upvotes - Downvotes) > 10
ORDER BY ActivityRank, DisplayName;
