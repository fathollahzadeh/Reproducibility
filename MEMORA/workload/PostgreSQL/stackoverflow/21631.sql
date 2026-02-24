
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
),
QuestionWithClosedReason AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.Comment,
        P.CreationDate,
        COALESCE(NULLIF(PH.Comment, ''), 'No Close Reason') AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  
),
TagAggregate AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 10 THEN 1 ELSE 0 END) AS HighScoringPosts
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        AVG(P.ViewCount) AS AvgViewCount,
        COUNT(C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UR.UserId,
    UR.Reputation,
    UR.TotalBounty,
    UR.TotalPosts,
    UR.TotalQuestions,
    UR.TotalAnswers,
    COALESCE(Q.CloseReason, 'Open') AS LastCloseReason,
    TA.TagName,
    TA.PostCount,
    TA.HighScoringPosts,
    UA.AvgViewCount,
    UA.TotalComments
FROM 
    UserReputation UR
LEFT JOIN 
    (SELECT UserId, MAX(CreationDate) AS LastCloseDate FROM QuestionWithClosedReason GROUP BY UserId) AS QC ON UR.UserId = QC.UserId
LEFT JOIN 
    QuestionWithClosedReason Q ON QC.UserId = Q.PostId AND Q.CreationDate = QC.LastCloseDate
LEFT JOIN 
    TagAggregate TA ON TA.PostCount > 0
LEFT JOIN 
    UserActivity UA ON UA.UserId = UR.UserId
WHERE 
    UR.TotalPosts > 0
ORDER BY 
    UR.Reputation DESC,
    TA.PostCount DESC
LIMIT 100;
