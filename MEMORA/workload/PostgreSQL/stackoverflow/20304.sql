
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation IS NULL THEN 'Unknown Reputation'
            WHEN Reputation = 0 THEN 'New User'
            WHEN Reputation BETWEEN 1 AND 100 THEN 'Novice'
            WHEN Reputation BETWEEN 101 AND 500 THEN 'Intermediate'
            WHEN Reputation BETWEEN 501 AND 1000 THEN 'Experienced'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users
),
PostReputation AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotesCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotesCount,
        CASE 
            WHEN COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) - COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) = 0 THEN 'No Votes'
            WHEN COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) - COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) > 0 THEN 'Positive Reputation'
            ELSE 'Negative Reputation'
        END AS PostReputationLevel
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
ClosedPostDetails AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseVoteCount,
        STRING_AGG(DISTINCT CRT.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    INNER JOIN CloseReasonTypes CRT ON CAST(PH.Comment AS INT) = CRT.Id
    WHERE PH.PostHistoryTypeId = 10 
    GROUP BY PH.PostId
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeList
    FROM Badges B
    GROUP BY B.UserId
),
FinalResults AS (
    SELECT 
        U.DisplayName,
        U.CreationDate,
        UR.ReputationLevel,
        P.Id AS PostId,
        P.Title,
        PR.UpVotesCount,
        PR.DownVotesCount,
        PR.PostReputationLevel,
        CP.CloseVoteCount,
        CP.CloseReasons,
        UB.BadgeCount,
        UB.BadgeList
    FROM Users U
    JOIN UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN PostReputation PR ON P.Id = PR.PostId
    LEFT JOIN ClosedPostDetails CP ON P.Id = CP.PostId
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    WHERE U.Reputation IS NOT NULL
    AND (P.AcceptedAnswerId IS NULL OR P.AcceptedAnswerId NOT IN (SELECT Id FROM Posts WHERE PostTypeId = 2))
)
SELECT 
    F.*,
    CASE 
        WHEN F.CloseVoteCount IS NULL THEN 'Open'
        WHEN F.CloseVoteCount > 0 THEN 'Closed'
        ELSE 'Status Unknown'
    END AS PostStatus,
    COALESCE(NULLIF(F.BadgeList, ''), 'No Badges') AS BadgeSummary
FROM FinalResults F
ORDER BY F.ReputationLevel DESC, F.UpVotesCount DESC, F.BadgeCount DESC;
