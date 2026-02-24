
WITH UserVotes AS (
    SELECT 
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM Votes V
    GROUP BY V.UserId
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM PostLinks PL WHERE PL.PostId = P.Id AND PL.LinkTypeId = 3) AS DuplicateCount
    FROM Posts P
),
RankedPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.ViewCount,
        PS.CommentCount,
        PS.DuplicateCount,
        ROW_NUMBER() OVER (ORDER BY PS.Score DESC, PS.ViewCount DESC) AS Rank
    FROM PostStats PS
)
SELECT 
    UP.DisplayName,
    COALESCE(U.Upvotes, 0) AS TotalUpvotes,
    COALESCE(U.Downvotes, 0) AS TotalDownvotes,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.CommentCount,
    RP.DuplicateCount
FROM RankedPosts RP
LEFT JOIN Users UP ON UP.Id IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = RP.PostId)
LEFT JOIN UserVotes U ON U.UserId = UP.Id
WHERE RP.Rank <= 10
ORDER BY RP.Rank, RP.Score DESC;
