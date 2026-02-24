
WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TagUsage AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.CommentCount,
        PS.UpvoteCount,
        PS.DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC, PS.CreationDate DESC) AS PostRank
    FROM 
        PostStatistics PS
)
SELECT 
    U.DisplayName AS UserName,
    UVC.TotalUpvotes,
    UVC.TotalDownvotes,
    TP.TagName,
    TP.PostCount,
    TP.TotalViews,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.CommentCount,
    RP.UpvoteCount,
    RP.DownvoteCount
FROM 
    UserVoteCounts UVC
JOIN 
    Users U ON U.Id = UVC.UserId
LEFT JOIN 
    TagUsage TP ON TP.PostCount > 10 
LEFT JOIN 
    RankedPosts RP ON RP.PostRank <= 5 
WHERE 
    (UVC.TotalUpvotes - UVC.TotalDownvotes) > 0 
ORDER BY 
    UVC.TotalUpvotes DESC, UVC.TotalDownvotes ASC;
