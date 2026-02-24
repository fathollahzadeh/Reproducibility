WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostScore AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(PH.UserId, -1) AS LastEditedUserId,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.LastEditDate DESC) AS rn
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 34)
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        US.DisplayName AS LastEditor,
        US.UpVotes,
        US.DownVotes,
        RANK() OVER (ORDER BY PS.Score DESC, PS.Title) AS ScoreRank
    FROM PostScore PS
    JOIN UserVoteStats US ON PS.LastEditedUserId = US.UserId
    WHERE PS.rn = 1
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.LastEditor,
    RP.UpVotes,
    RP.DownVotes,
    CASE 
        WHEN RP.UpVotes + RP.DownVotes = 0 THEN 0 
        ELSE ROUND((CAST(RP.UpVotes AS DECIMAL) / (RP.UpVotes + RP.DownVotes)) * 100, 2) 
    END AS UpvotePercentage,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId IN (6, 10, 11)) THEN 'Closed'
        ELSE 'Active' 
    END AS PostStatus
FROM RankedPosts RP
WHERE RP.ScoreRank <= 10
ORDER BY RP.Score DESC, RP.Title;
