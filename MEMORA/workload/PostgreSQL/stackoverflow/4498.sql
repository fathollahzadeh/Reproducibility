
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE -1 END ELSE 0 END) AS NetVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(C) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE -1 END) AS Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
FinalResults AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        PA.PostId,
        PA.Title,
        PA.CreationDate,
        PA.CommentCount,
        PA.UpVotes,
        PA.DownVotes,
        PA.Score,
        UA.NetVotes
    FROM UserVoteCounts UA
    JOIN PostAnalytics PA ON UA.UserId = PA.OwnerUserId
    WHERE UA.NetVotes IS NOT NULL
)

SELECT 
    UserId,
    DisplayName,
    PostId,
    Title,
    CreationDate,
    CommentCount,
    UpVotes,
    DownVotes,
    Score,
    NetVotes
FROM FinalResults
WHERE Score > 0
ORDER BY NetVotes DESC, CreationDate ASC
LIMIT 10;
