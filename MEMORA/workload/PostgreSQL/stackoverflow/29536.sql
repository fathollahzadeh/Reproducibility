
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title, P.Body, U.DisplayName, P.CreationDate
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.CommentCount,
        RP.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY RP.CreationDate DESC) AS NewRank
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank = 1
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.OwnerDisplayName,
    CAST(TP.CreationDate AS VARCHAR) AS FormattedCreationDate,
    TP.CommentCount,
    TP.AnswerCount,
    CASE 
        WHEN TP.AnswerCount > 0 THEN 'Has Answers' 
        ELSE 'No Answers' 
    END AS AnswerStatus,
    STRING_AGG(PT.Name, ', ') AS PostTypeNames
FROM 
    TopPosts TP
LEFT JOIN 
    PostTypes PT ON PT.Id = (SELECT PostTypeId FROM Posts WHERE Id = TP.PostId LIMIT 1)
GROUP BY 
    TP.PostId, TP.Title, TP.OwnerDisplayName, TP.CreationDate, TP.CommentCount, TP.AnswerCount
HAVING 
    TP.AnswerCount >= 2
ORDER BY 
    TP.CreationDate DESC
LIMIT 10;
