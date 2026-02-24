
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass,
        MAX(B.Date) AS LatestBadgeDate
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS RN,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score, P.AnswerCount, P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS CloseDate,
        PH.UserId AS CloserUserId,
        C.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON CAST(PH.Comment AS INTEGER) = C.Id
    WHERE PH.PostHistoryTypeId = 10
),
PostVoteSummary AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 4 THEN 1 ELSE 0 END) AS OffensiveVotes
    FROM Votes V
    GROUP BY V.PostId
)
SELECT 
    U.DisplayName,
    U.BadgeCount,
    U.HighestBadgeClass,
    P.Title,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.Tags,
    COALESCE(CP.CloseDate, NULL) AS CloseDate,
    CP.CloseReason,
    PVS.UpVotes,
    PVS.DownVotes,
    PVS.OffensiveVotes
FROM UserBadges U
JOIN PostMetrics P ON U.UserId = P.OwnerUserId
LEFT JOIN ClosedPosts CP ON P.PostId = CP.PostId
LEFT JOIN PostVoteSummary PVS ON P.PostId = PVS.PostId
WHERE U.BadgeCount > 0
  AND P.RN = 1
  AND (UPPER(P.Title) LIKE '%SQL%' OR P.ViewCount > 100)
ORDER BY U.BadgeCount DESC, P.ViewCount DESC
LIMIT 50;
