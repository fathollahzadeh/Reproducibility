WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '90 days'
        AND P.ViewCount IS NOT NULL
),


CumulativeScores AS (
    SELECT 
        PostId,
        Title,
        Score,
        OwnerDisplayName,
        SUM(Score) OVER (PARTITION BY OwnerDisplayName ORDER BY LastActivityDate) AS CumulativeScore,
        ROW_NUMBER() OVER (PARTITION BY OwnerDisplayName ORDER BY LastActivityDate DESC) AS Ranking
    FROM 
        RankedPosts
    WHERE
        PostRank <= 5
)


SELECT 
    CS.OwnerDisplayName,
    CS.Title,
    CS.Score,
    CS.CumulativeScore,
    COALESCE(PHT.Name, 'No History') AS PostHistoryType,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = CS.PostId AND V.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = CS.PostId AND V.VoteTypeId = 3) AS Downvotes
FROM 
    CumulativeScores CS
LEFT JOIN 
    PostHistory PH ON CS.PostId = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
WHERE 
    CS.Ranking <= 3 
ORDER BY 
    CS.OwnerDisplayName, CS.Score DESC;