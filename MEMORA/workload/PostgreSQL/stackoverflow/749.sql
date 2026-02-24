WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankByScore
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
      AND P.PostTypeId = 1
),
TotalVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM Comments C
    GROUP BY C.PostId
),
AcceptedAnswers AS (
    SELECT 
        A.AcceptedAnswerId,
        COUNT(A.Id) AS AcceptedCount
    FROM Posts A
    WHERE A.PostTypeId = 2
    GROUP BY A.AcceptedAnswerId
)
SELECT 
    RP.Title,
    RP.Score,
    RP.ViewCount,
    COALESCE(TV.UpVotes, 0) AS UpVotes,
    COALESCE(TV.DownVotes, 0) AS DownVotes,
    COALESCE(PC.CommentCount, 0) AS CommentCount,
    COALESCE(AA.AcceptedCount, 0) AS AcceptedCount,
    RP.CreationDate,
    U.DisplayName AS OwnerDisplayName
FROM RankedPosts RP
LEFT JOIN TotalVotes TV ON RP.PostId = TV.PostId
LEFT JOIN PostComments PC ON RP.PostId = PC.PostId
LEFT JOIN AcceptedAnswers AA ON RP.PostId = AA.AcceptedAnswerId
JOIN Users U ON RP.OwnerUserId = U.Id
WHERE RP.RankByScore <= 5
ORDER BY RP.Score DESC, RP.ViewCount DESC;