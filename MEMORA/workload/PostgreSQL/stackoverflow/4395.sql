WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (5, 6, 7) THEN 1 ELSE 0 END), 0) AS TotalInteractions
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostInteractionCounts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 ELSE NULL END) AS CommentCount,
        COUNT(CASE WHEN V.PostId IS NOT NULL AND V.VoteTypeId = 2 THEN 1 ELSE NULL END) AS UpvoteCount,
        COUNT(CASE WHEN V.PostId IS NOT NULL AND V.VoteTypeId = 3 THEN 1 ELSE NULL END) AS DownvoteCount,
        COUNT(CASE WHEN PH.UserId IS NOT NULL AND PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE NULL END) AS CloseReopenCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title
),
RankedPosts AS (
    SELECT 
        PIC.*,
        RANK() OVER (ORDER BY (UpvoteCount - DownvoteCount) DESC) AS PostRank
    FROM 
        PostInteractionCounts PIC
)
SELECT 
    U.DisplayName,
    U.TotalUpvotes,
    U.TotalDownvotes,
    P.Title AS PostTitle,
    P.CommentCount,
    P.UpvoteCount,
    P.DownvoteCount,
    P.CloseReopenCount,
    P.PostRank
FROM 
    UserVoteStats U
JOIN 
    RankedPosts P ON U.UserId = P.PostRank
WHERE 
    U.TotalUpvotes > U.TotalDownvotes
ORDER BY 
    U.TotalUpvotes DESC,
    P.PostRank
LIMIT 10;