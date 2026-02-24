
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        PostCount,
        QuestionCount,
        AnswerCount,
        PositiveScoreCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
),
MostActiveUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.PostCount,
        U.QuestionCount,
        U.AnswerCount,
        U.PositiveScoreCount
    FROM 
        TopUsers U
    WHERE 
        U.Rank <= 10
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        C.Text AS CommentText,
        CASE 
            WHEN PH.UserId IS NOT NULL THEN PH.UserId 
            ELSE -1 
        END AS LastModifiedByUserId,
        COALESCE(PH.CreationDate, P.CreationDate) AS LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
)
SELECT 
    AU.DisplayName AS ActiveUser,
    AU.Reputation AS UserReputation,
    COUNT(DISTINCT PA.PostId) AS ActivePostCount,
    SUM(CASE WHEN PA.Score > 0 THEN 1 ELSE 0 END) AS PositivePostsCount,
    COUNT(DISTINCT C.Id) AS CommentCount,
    COUNT(DISTINCT PH.Id) AS HistoryChangeCount,
    MAX(PA.LastActivityDate) AS LastActivePostDate
FROM 
    MostActiveUsers AU
JOIN 
    PostActivity PA ON PA.LastModifiedByUserId = AU.UserId
LEFT JOIN 
    Comments C ON PA.PostId = C.PostId
LEFT JOIN 
    PostHistory PH ON PA.PostId = PH.PostId
GROUP BY 
    AU.DisplayName, AU.Reputation
ORDER BY 
    AU.Reputation DESC, ActivePostCount DESC;
