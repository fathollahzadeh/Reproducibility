WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.PostId IS NOT NULL THEN 1 END) AS VoteCount,
        RANK() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS TagRank
    FROM
        Posts P
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    WHERE
        P.PostTypeId = 1 AND  
        P.Score > 0  
    GROUP BY
        P.Id, P.Title, P.Body, P.Tags, U.DisplayName, P.CreationDate, P.Score
)

SELECT
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.CreationDate,
    RP.Score,
    RP.CommentCount,
    RP.VoteCount,
    RP.Tags,
    (SELECT STRING_AGG(B.Name, ', ') 
     FROM Badges B 
     WHERE B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = RP.PostId)) AS OwnerBadges,
    PHT.Comment AS LastEditComment
FROM
    RankedPosts RP
LEFT JOIN
    PostHistory PHT ON RP.PostId = PHT.PostId
WHERE
    PHT.CreationDate = (
        SELECT MAX(CreationDate) 
        FROM PostHistory 
        WHERE PostId = RP.PostId AND PostHistoryTypeId IN (4, 5)  
    )
ORDER BY
    RP.TagRank, RP.Score DESC
LIMIT 10;