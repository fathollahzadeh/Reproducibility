
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
),
PostScores AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.OwnerUserId,
        COUNT(C.Id) AS TotalComments,
        COALESCE(AVG(V.VoteTypeId), 0) AS AverageVoteType
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.Score, P.OwnerUserId
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.TotalComments,
        RU.UserId,
        RU.DisplayName,
        RU.Reputation,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC, PS.TotalComments DESC) AS PostRank
    FROM PostScores PS
    JOIN RankedUsers RU ON PS.OwnerUserId = RU.UserId
    WHERE PS.Score > 0
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.TotalComments,
    TP.DisplayName AS Author,
    TP.Reputation AS AuthorReputation,
    TP.PostRank
FROM TopPosts TP
WHERE TP.PostRank <= 10
ORDER BY TP.Score DESC;
