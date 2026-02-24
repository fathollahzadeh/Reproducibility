
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    U.DisplayName,
    U.TotalVotes,
    U.Upvotes,
    U.Downvotes,
    U.TotalBounty,
    P.Title,
    P.CommentCount,
    P.UpvoteCount,
    P.DownvoteCount,
    P.LastEditDate,
    CASE 
        WHEN P.LastEditDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' THEN 'Stale'
        WHEN P.LastEditDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' THEN 'Recent'
    END AS PostRecency
FROM 
    UserVoteStats U
JOIN 
    PostStats P ON P.UpvoteCount > 10 AND U.UserId IN (
        SELECT DISTINCT UserId 
        FROM Votes 
        WHERE PostId = P.PostId AND VoteTypeId = 2
    )
WHERE 
    U.TotalVotes > 0
ORDER BY 
    U.TotalVotes DESC, P.CommentCount DESC;
