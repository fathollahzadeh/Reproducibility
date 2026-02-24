
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        P.CreationDate,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT 
            unnest(string_to_array(substring(Tags, 2, LENGTH(Tags) - 2), '><')) AS TagName,
            PostId 
         FROM 
            Posts) T ON P.Id = T.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AnswerCount, P.CreationDate
), UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000 
), TopQuestions AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.CreationDate,
        PS.Tags,
        RANK() OVER (ORDER BY PS.Score DESC, PS.ViewCount DESC) AS Rank
    FROM 
        PostStatistics PS
    WHERE 
        PS.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
)
SELECT 
    TQ.Title,
    TQ.Score,
    TQ.ViewCount,
    TQ.AnswerCount,
    TQ.CommentCount,
    TQ.Tags,
    U.DisplayName,
    U.Reputation
FROM 
    TopQuestions TQ
JOIN 
    Users U ON TQ.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
WHERE 
    TQ.Rank <= 10 
ORDER BY 
    TQ.Score DESC;
