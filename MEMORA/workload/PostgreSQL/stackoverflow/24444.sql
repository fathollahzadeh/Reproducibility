WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    GROUP BY U.Id, U.Reputation
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - P.CreationDate)) / 3600 AS AgeInHours,
        P.Score,
        COALESCE(H.TypeCount, 0) AS HistoryCount,
        COALESCE(VoteCounts.UpVotes, 0) AS TotalUpVotes,
        COALESCE(VoteCounts.DownVotes, 0) AS TotalDownVotes
    FROM Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TypeCount
        FROM PostHistory
        GROUP BY PostId
    ) H ON P.Id = H.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
        FROM Votes 
        GROUP BY PostId
    ) VoteCounts ON P.Id = VoteCounts.PostId
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.AgeInHours,
        PS.Score,
        PS.TotalUpVotes,
        PS.TotalDownVotes,
        RANK() OVER (ORDER BY PS.Score DESC, PS.AgeInHours ASC) AS ScoreRank
    FROM PostStatistics PS
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UV.UpVotes,
    UV.DownVotes,
    COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(UB.BadgeNames, 'No Badges') AS UserBadges,
    RP.Title,
    RP.AgeInHours,
    RP.Score,
    RP.ScoreRank
FROM UserVotes UV
JOIN Users U ON UV.UserId = U.Id
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
JOIN RankedPosts RP ON RP.ScoreRank <= 10 
WHERE (U.Reputation > 100 OR (U.Reputation IS NULL AND U.Location IS NOT NULL)) 
AND (RP.AgeInHours IS NOT NULL AND RP.AgeInHours < 72) 
ORDER BY RP.ScoreRank, U.Reputation DESC;