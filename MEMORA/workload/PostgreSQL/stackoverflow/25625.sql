
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostID,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS Author,
        P.CreationDate,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, U.DisplayName, P.CreationDate
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(RP.CommentCount) AS TotalComments,
        SUM(RP.UpvoteCount) AS TotalUpvotes,
        SUM(RP.DownvoteCount) AS TotalDownvotes
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN 
        RankedPosts RP ON P.Id = RP.PostID
    GROUP BY 
        T.TagName
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.TotalComments,
    TS.TotalUpvotes,
    TS.TotalDownvotes,
    (TS.TotalUpvotes - TS.TotalDownvotes) AS NetVotes,
    (TS.TotalComments * 1.0 / NULLIF(TS.PostCount, 0)) AS AvgCommentsPerPost,
    (TS.TotalUpvotes * 1.0 / NULLIF(TS.PostCount, 0)) AS AvgUpvotesPerPost,
    (TS.TotalDownvotes * 1.0 / NULLIF(TS.PostCount, 0)) AS AvgDownvotesPerPost
FROM 
    TagStats TS
ORDER BY 
    NetVotes DESC, AvgCommentsPerPost DESC
LIMIT 10;
