
WITH PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CommentCount,
        P.AnswerCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        COUNT(V.Id) AS TotalVotes,
        MAX(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        MAX(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        P.PostTypeId
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, P.CommentCount, P.AnswerCount, P.CreationDate, 
        U.DisplayName, U.Reputation, P.PostTypeId
),
PostTypes AS (
    SELECT 
        PT.Id AS PostTypeId,
        PT.Name AS PostTypeName
    FROM 
        PostTypes PT
)
SELECT 
    PE.PostId,
    PE.Title,
    PT.PostTypeName,
    PE.ViewCount,
    PE.Score,
    PE.CommentCount,
    PE.AnswerCount,
    PE.CreationDate,
    PE.OwnerDisplayName,
    PE.OwnerReputation,
    PE.TotalVotes,
    PE.TotalUpvotes,
    PE.TotalDownvotes
FROM 
    PostEngagement PE
JOIN 
    PostTypes PT ON PE.PostTypeId = PT.PostTypeId
ORDER BY 
    PE.ViewCount DESC;
