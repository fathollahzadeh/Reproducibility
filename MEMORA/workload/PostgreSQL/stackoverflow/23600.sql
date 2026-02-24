
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Votes V ON V.UserId = U.Id
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN Badges B ON B.UserId = U.Id
    GROUP BY U.Id, U.DisplayName
),
FilteredStats AS (
    SELECT 
        UserId,
        DisplayName,
        Upvotes,
        Downvotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        AnswerCount,
        TotalViews,
        PostCount,
        (Upvotes - Downvotes) AS Score,
        RANK() OVER (ORDER BY (Upvotes - Downvotes + (GoldBadges * 3) + (SilverBadges * 2) + BronzeBadges) DESC) AS Rank,
        CASE 
            WHEN (GoldBadges + SilverBadges + BronzeBadges) = 0 THEN 'No Badges'
            ELSE 'Has Badges'
        END AS BadgeStatus
    FROM UserStats
),
TopUsers AS (
    SELECT
        F.*,
        ROW_NUMBER() OVER (PARTITION BY BadgeStatus ORDER BY Score DESC) AS BadgeRank
    FROM FilteredStats F
)
SELECT 
    UserId,
    DisplayName,
    Upvotes,
    Downvotes,
    Score,
    BadgeStatus,
    Rank,
    BadgeRank,
    CASE 
        WHEN TotalViews IS NULL OR TotalViews = 0 THEN 'No Views Recorded'
        WHEN TotalViews > 1000 THEN 'Popular User'
        ELSE 'Less Popular User'
    END AS PopularityStatus
FROM TopUsers
WHERE Rank <= 10 
    AND (Score > 0 OR BadgeStatus = 'No Badges')
ORDER BY Score DESC, BadgeStatus ASC;
