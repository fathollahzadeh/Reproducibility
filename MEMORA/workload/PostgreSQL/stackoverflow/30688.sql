WITH RECURSIVE UserVotes AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS VoteBalance
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostAggregates AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS ClosureCount,
        COALESCE(VB.TotalUpVotes, 0) AS TotalUpVotes,
        COALESCE(VB.TotalDownVotes, 0) AS TotalDownVotes,
        COALESCE(VB.VoteBalance, 0) AS VoteBalance
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN UserVotes VB ON P.OwnerUserId = VB.UserId
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, VB.TotalUpVotes, VB.TotalDownVotes, VB.VoteBalance
),
RankedPosts AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.Score,
        PA.ViewCount,
        PA.CommentCount,
        PA.ClosureCount,
        PA.TotalUpVotes,
        PA.TotalDownVotes,
        PA.VoteBalance,
        ROW_NUMBER() OVER (ORDER BY PA.Score DESC, PA.ViewCount DESC) AS Rank
    FROM PostAggregates PA
    WHERE PA.Score > 0 AND PA.ClosureCount < 5
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.CommentCount,
    RP.ClosureCount,
    RP.TotalUpVotes,
    RP.TotalDownVotes,
    RP.VoteBalance,
    CASE 
        WHEN RP.VoteBalance > 0 THEN 'Positive' 
        WHEN RP.VoteBalance < 0 THEN 'Negative' 
        ELSE 'Neutral' 
    END AS VoteStatus
FROM RankedPosts RP
WHERE RP.Rank <= 100
ORDER BY RP.Score DESC, RP.ViewCount DESC;
