
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        RP.TotalComments,
        RP.Upvotes,
        RP.Downvotes
    FROM RankedPosts RP
    WHERE RP.Rank <= 10
)
SELECT 
    TP.Title,
    TP.CreationDate,
    TP.OwnerDisplayName,
    TP.Score,
    TP.ViewCount,
    TP.TotalComments,
    TP.Upvotes,
    TP.Downvotes,
    CASE 
        WHEN TP.Upvotes >= TP.Downvotes THEN 'Positive Engagement'
        ELSE 'Negative Engagement'
    END AS EngagementType
FROM TopPosts TP
ORDER BY TP.Score DESC, TP.ViewCount DESC;
