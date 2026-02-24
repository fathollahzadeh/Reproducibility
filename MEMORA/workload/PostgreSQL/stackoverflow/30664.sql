
WITH RecursivePostCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(A.Id) AS AnswerCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.PostTypeId = 1
    GROUP BY P.Id
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
FilteredPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        R.AnswerCount,
        R.CommentCount,
        U.Reputation AS OwnerReputation,
        U.DisplayName AS OwnerDisplayName,
        P.OwnerUserId
    FROM Posts P
    INNER JOIN RecursivePostCounts R ON P.Id = R.PostId
    INNER JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
      AND (R.AnswerCount > 5 OR R.CommentCount > 10)
),
RankedPosts AS (
    SELECT 
        FP.*, 
        ROW_NUMBER() OVER (PARTITION BY FP.OwnerUserId ORDER BY FP.LastActivityDate DESC) AS UserRank
    FROM FilteredPosts FP
)
SELECT 
    F.Title,
    F.CreationDate,
    F.LastActivityDate,
    F.OwnerDisplayName,
    F.OwnerReputation,
    COALESCE(B.GoldBadges, 0) AS GoldBadges,
    COALESCE(B.SilverBadges, 0) AS SilverBadges,
    COALESCE(B.BronzeBadges, 0) AS BronzeBadges
FROM RankedPosts F
LEFT JOIN UserReputation B ON F.OwnerUserId = B.UserId
WHERE F.UserRank <= 3
ORDER BY F.LastActivityDate DESC;
