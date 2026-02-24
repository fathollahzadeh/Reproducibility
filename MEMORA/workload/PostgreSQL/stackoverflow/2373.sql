
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT V.PostId) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(PC.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Posts PC ON P.Id = PC.ParentId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND 
        P.Score > 0
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, PC.AcceptedAnswerId, P.OwnerUserId
)
SELECT 
    U.DisplayName,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.AcceptedAnswerId,
    PS.CommentCount,
    PS.VoteCount,
    U.TotalUpvotes,
    U.TotalDownvotes,
    PS.UserPostRank
FROM 
    UserVoteSummary U
INNER JOIN PostSummary PS ON U.UserId = PS.OwnerUserId
WHERE 
    (U.TotalUpvotes - U.TotalDownvotes) > 10
    AND PS.CommentCount > 5
ORDER BY 
    U.TotalUpvotes DESC, PS.Score DESC
LIMIT 50;
