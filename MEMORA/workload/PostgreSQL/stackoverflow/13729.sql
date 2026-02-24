
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS OwnerReputation,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCountTotal,
        PH.RevisionGUID,
        PH.CreationDate AS LastEditedDate
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= '2023-01-01' 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, U.Reputation, PH.RevisionGUID, PH.CreationDate
)
SELECT 
    AVG(ViewCount) AS AverageViewCount,
    AVG(Score) AS AverageScore,
    AVG(AnswerCount) AS AverageAnswerCount,
    AVG(CommentCountTotal) AS AverageCommentCount,
    SUM(Upvotes) AS TotalUpvotes,
    SUM(Downvotes) AS TotalDownvotes
FROM 
    PostMetrics;
