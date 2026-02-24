
WITH UserRanking AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        AVG(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE NULL END) AS AverageUpVotes, 
        AVG(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE NULL END) AS AverageDownVotes,
        COALESCE(MAX(PH.CreationDate), '1900-01-01') AS LastEditDate,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Unaccepted'
        END AS AnswerStatus,
        COALESCE(NULLIF(STRING_AGG(DISTINCT T.TagName, ', '), ''), 'No Tags') AS Tags
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6)
    LEFT JOIN LATERAL (
        SELECT UNNEST(STRING_TO_ARRAY(P.Tags, '><')) AS TagName
    ) T ON TRUE
    GROUP BY P.Id, P.Title, P.PostTypeId
),
ClosedPostsCTE AS (
    SELECT 
        PH.PostId,
        PH.Comment AS CloseReason,
        PH.CreationDate,
        PH.UserId
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
),
PostComparison AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.AverageUpVotes - PS.AverageDownVotes AS VoteBalance,
        U.UserId,
        U.DisplayName,
        COALESCE(CP.CloseReason, 'Not Closed') AS PostClosureReason
    FROM PostSummary PS
    JOIN UserRanking U ON PS.PostId = U.UserId
    LEFT JOIN ClosedPostsCTE CP ON PS.PostId = CP.PostId
)
SELECT 
    PC.PostId,
    PC.Title,
    PC.CommentCount,
    PC.VoteBalance,
    PC.DisplayName,
    PC.PostClosureReason
FROM PostComparison PC
WHERE PC.VoteBalance > 0
AND NOT EXISTS (
    SELECT 1 
    FROM ClosedPostsCTE C
    WHERE C.PostId = PC.PostId
)
ORDER BY PC.VoteBalance DESC, PC.CommentCount DESC
LIMIT 10;
