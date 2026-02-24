
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT CASE WHEN V.VoteTypeId IN (2, 3) THEN V.PostId END) AS TotalVotedPosts
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostActivity AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COALESCE(COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.Comment IS NOT NULL THEN 1 END), 0) AS HistoryEntryCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score
),
TopPosts AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.ViewCount,
        PA.Score,
        RANK() OVER (ORDER BY PA.Score DESC, PA.ViewCount DESC) AS PostRank
    FROM PostActivity PA
    WHERE PA.Score > 0
)
SELECT 
    UVs.DisplayName,
    UVs.UpVotes,
    UVs.DownVotes,
    TP.Title,
    TP.ViewCount,
    TP.Score,
    TP.PostRank,
    CASE 
        WHEN UVs.TotalVotedPosts > 0 THEN 'Active Voter'
        ELSE 'Inactive Voter'
    END AS VotingStatus
FROM UserVoteStats UVs
JOIN TopPosts TP ON UVs.UserId = TP.PostId
WHERE UVs.UpVotes - UVs.DownVotes > 0
AND TP.PostRank <= 10
ORDER BY TP.Score DESC, UVs.UpVotes DESC;
