WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(CM.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score
),
RankedPosts AS (
    SELECT 
        PS.*,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC, PS.CommentCount DESC) AS PostRank
    FROM PostStatistics PS
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    PPS.PostId,
    PPS.Title,
    PPS.CreationDate,
    PPS.Score,
    PPS.CommentCount,
    PPS.UpVoteCount,
    PPS.DownVoteCount,
    CASE 
        WHEN PPS.Score IS NULL THEN 'No Score'
        ELSE CASE 
            WHEN PPS.Score > 10 THEN 'High Score'
            WHEN PPS.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
            ELSE 'Low Score' 
        END 
    END AS ScoreCategory,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PPS.PostId AND V.VoteTypeId = 4) AS NominationCount
FROM UserVoteStats UPS
JOIN RankedPosts PPS ON UPS.TotalVotes > 5 AND UPS.UserId = PPS.PostId
WHERE PPS.PostRank <= 10
ORDER BY UPS.TotalVotes DESC, PPS.Score DESC;