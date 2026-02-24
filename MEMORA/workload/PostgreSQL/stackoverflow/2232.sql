WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadgeCount,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadgeCount,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadgeCount
    FROM Badges
    GROUP BY UserId
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        P.CreationDate,
        P.Score,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount
    FROM Posts P
),
UserPostMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(CASE WHEN PS.Score IS NOT NULL THEN PS.Score ELSE 0 END) AS TotalPostScore,
        COUNT(DISTINCT PS.PostId) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN PS.AcceptedAnswerId IS NOT NULL THEN PS.PostId END) AS AcceptedAnswers
    FROM Users U
    LEFT JOIN PostSummary PS ON U.Id = PS.AcceptedAnswerId
    GROUP BY U.Id, U.DisplayName, U.Reputation
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UBC.GoldBadgeCount, 0) AS GoldBadges,
    COALESCE(UBC.SilverBadgeCount, 0) AS SilverBadges,
    COALESCE(UBC.BronzeBadgeCount, 0) AS BronzeBadges,
    UPM.TotalPosts,
    UPM.AcceptedAnswers,
    UPM.TotalPostScore,
    CASE 
        WHEN U.LastAccessDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active'
    END AS UserStatus
FROM Users U
LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
LEFT JOIN UserPostMetrics UPM ON U.Id = UPM.UserId
ORDER BY U.Reputation DESC, U.DisplayName ASC
LIMIT 100;