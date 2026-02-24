WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.Rank,
    RP.CommentCount,
    RP.UpvoteCount,
    RP.DownvoteCount,
    COALESCE(B.Name, 'No Badge') AS BadgeName,
    CASE 
        WHEN RP.CommentCount = 0 THEN 'No Comments'
        ELSE 'Comments Available'
    END AS CommentStatus,
    CASE 
        WHEN RP.UpvoteCount > RP.DownvoteCount THEN 'Positive Sentiment'
        WHEN RP.UpvoteCount < RP.DownvoteCount THEN 'Negative Sentiment'
        ELSE 'Neutral Sentiment'
    END AS SentimentAnalysis
FROM 
    RankedPosts RP
LEFT JOIN 
    Badges B ON B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = RP.PostId)
WHERE 
    RP.Rank <= 5 
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC;