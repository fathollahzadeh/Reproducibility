
WITH RankedUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostDetail AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.DisplayName
),
TopPosts AS (
    SELECT
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.ViewCount,
        PD.Score,
        PD.OwnerDisplayName,
        PD.CommentCount,
        PD.TotalBounty,
        R.ReputationRank
    FROM PostDetail PD
    JOIN RankedUsers R ON PD.OwnerDisplayName = R.DisplayName
    WHERE PD.Score > 10
    ORDER BY PD.Score DESC, PD.ViewCount DESC
    LIMIT 10
)
SELECT
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.ViewCount,
    TP.Score,
    TP.OwnerDisplayName,
    TP.CommentCount,
    TP.TotalBounty,
    CASE
        WHEN TP.ReputationRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM TopPosts TP
LEFT JOIN PostHistory PH ON TP.PostId = PH.PostId AND PH.PostHistoryTypeId IN (10, 11) 
WHERE PH.Id IS NULL
ORDER BY TP.Score DESC, TP.ViewCount DESC;
