
WITH PostAggregate AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        PT.Name AS PostType,
        COALESCE(MAX(PH.CreationDate), P.CreationDate) AS LastModified
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'
    GROUP BY 
        P.Id, P.Title, PT.Name
), RankedPosts AS (
    SELECT 
        PA.*,
        ROW_NUMBER() OVER (ORDER BY (UpvoteCount - DownvoteCount) DESC, CommentCount DESC, LastModified DESC) AS Rank
    FROM 
        PostAggregate PA
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CommentCount,
    RP.UpvoteCount,
    RP.DownvoteCount,
    RP.BadgeCount,
    RP.PostType,
    RP.Rank
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 10
ORDER BY 
    RP.Rank;
