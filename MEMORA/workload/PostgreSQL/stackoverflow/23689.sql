
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (10, 12) THEN 1 ELSE 0 END) AS DeleteVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount,
        MAX(COALESCE(PH.CreationDate, '1970-01-01'::timestamp)) AS LastHistoryDate,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(DISTINCT C.Id) DESC) AS RankByComments
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate < TIMESTAMP '2024-10-01 12:34:56' AND (P.ClosedDate IS NULL OR P.ClosedDate > TIMESTAMP '2024-10-01 12:34:56')
    GROUP BY P.Id, P.Title, P.OwnerUserId
),
UserPostPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        UP.TotalVotes,
        UP.UpVotes,
        UP.DownVotes,
        BP.PostId,
        BP.Title,
        BP.CommentCount,
        BP.RelatedPostCount,
        BP.LastHistoryDate,
        CASE 
            WHEN BP.RankByComments <= 5 THEN 'High Engagement'
            WHEN BP.RankByComments > 5 AND BP.RankByComments <= 10 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM Users U
    JOIN UserVoteCounts UP ON U.Id = UP.UserId
    JOIN PostStatistics BP ON U.Id = BP.OwnerUserId
    WHERE U.Reputation > 1000
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    U.CommentCount,
    U.RelatedPostCount,
    U.LastHistoryDate,
    U.EngagementLevel,
    CASE
        WHEN U.LastHistoryDate IS NULL THEN 'No activity'
        WHEN U.LastHistoryDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM UserPostPerformance U
WHERE U.TotalVotes > 0 AND U.EngagementLevel = 'High Engagement'
ORDER BY U.Reputation DESC, U.TotalVotes DESC;
