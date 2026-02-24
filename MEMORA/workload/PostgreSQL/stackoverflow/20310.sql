WITH UserBadgeSummary AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass,
        CASE 
            WHEN COUNT(B.Id) = 0 THEN 'No Badges'
            WHEN MAX(B.Class) = 1 THEN 'Gold'
            WHEN MAX(B.Class) = 2 THEN 'Silver'
            ELSE 'Bronze'
        END AS BadgeLevel
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        COALESCE(P.AcceptedAnswerId, -1) AS AnswerStatus,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
      AND P.PostTypeId = 1
),
AnswerStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS AnswerCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedCount
    FROM Posts P
    WHERE P.PostTypeId = 2
    GROUP BY P.OwnerUserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.ViewCount,
    R.AnswerStatus,
    A.AnswerCount,
    A.AcceptedCount,
    CASE 
        WHEN R.UserPostRank = 1 THEN 'Newest post'
        WHEN R.UserPostRank <= 5 THEN 'Recent posts'
        ELSE 'Other posts'
    END AS PostCategory
FROM Users U
LEFT JOIN UserBadgeSummary UB ON U.Id = UB.UserId
LEFT JOIN RecentPosts R ON U.Id = R.OwnerUserId
LEFT JOIN AnswerStats A ON U.Id = A.OwnerUserId
WHERE (UB.BadgeLevel = 'Gold' OR R.ViewCount > 100)
  AND (A.AcceptedCount > 0 OR R.AnswerStatus = -1)
ORDER BY U.Reputation DESC, R.CreationDate DESC;