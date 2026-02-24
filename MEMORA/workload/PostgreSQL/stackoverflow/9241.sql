WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Title,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS EditHistoryCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = P.Id AND VoteTypeId IN (2, 3)) AS TotalVotes,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.Title
),
FilteredPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.PostTypeId,
        PS.CommentCount,
        PS.EditHistoryCount,
        PS.UpVoteCount,
        PS.DownVoteCount,
        PS.TotalVotes,
        PS.LastEditDate
    FROM 
        PostStatistics PS
    WHERE 
        PS.CommentCount > 5 AND PS.UpVoteCount > PS.DownVoteCount
)
SELECT 
    F.PostId,
    F.Title,
    F.CommentCount,
    F.EditHistoryCount,
    F.UpVoteCount,
    F.DownVoteCount,
    F.LastEditDate
FROM 
    FilteredPosts F
JOIN 
    Users U ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = F.PostId)
WHERE 
    U.Reputation > 1000
ORDER BY 
    F.UpVoteCount DESC, F.CommentCount DESC
LIMIT 10;
