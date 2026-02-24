
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(NULLIF(P.Body, ''), '<no content>') AS BodyContent,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= '2022-01-01'
),
ActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.LastAccessDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostTypesCount AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
TopCloseReasons AS (
    SELECT 
        PH.Comment,
        PH.PostId
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    ORDER BY 
        PH.CreationDate DESC
    LIMIT 5
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.BodyContent,
    AU.DisplayName AS ActiveUserName,
    PT.TotalPosts AS PostTypeTotal,
    TCR.Comment AS LastCloseReason
FROM 
    PostStats PS
LEFT JOIN 
    ActiveUsers AU ON PS.UserPostRank = 1
LEFT JOIN 
    PostTypesCount PT ON PS.PostId IN (SELECT P.Id FROM Posts P WHERE P.PostTypeId = PT.PostTypeId)
LEFT JOIN 
    TopCloseReasons TCR ON PS.PostId = TCR.PostId
WHERE 
    (PS.ViewCount > 1000 OR PS.Score > 10)
AND 
    (PS.AnswerCount > 0 OR PS.CommentCount > 5)
ORDER BY 
    PS.Score DESC,
    PS.ViewCount DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
