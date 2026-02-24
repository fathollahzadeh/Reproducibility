
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
PostEngagement AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PH.UserId) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title
), 
HighEngagementPosts AS (
    SELECT 
        PE.PostId,
        PE.Title,
        PE.CommentCount,
        PE.EditCount,
        U.DisplayName,
        U.Reputation
    FROM 
        PostEngagement PE
    JOIN 
        Users U ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = PE.PostId)
    WHERE 
        PE.CommentCount > 5 AND PE.EditCount > 2
)
SELECT 
    U.Id AS UserId, 
    U.DisplayName, 
    U.Reputation, 
    COUNT(HEP.PostId) AS EngagedPostCount
FROM 
    Users U
LEFT JOIN 
    HighEngagementPosts HEP ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = HEP.PostId)
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    EngagedPostCount DESC, U.Reputation DESC
LIMIT 10;
