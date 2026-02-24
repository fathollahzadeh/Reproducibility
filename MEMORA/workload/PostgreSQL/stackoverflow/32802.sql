
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        1 AS Level,
        CAST(P.Title AS VARCHAR(300)) AS FullTitle
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  
    UNION ALL
    SELECT 
        P2.Id,
        P2.Title,
        P2.Score,
        P2.CreationDate,
        PH.Level + 1,
        CAST(CONCAT(PH.FullTitle, ' -> ', P2.Title) AS VARCHAR(300)) 
    FROM 
        Posts P2
    INNER JOIN 
        PostHierarchy PH ON P2.ParentId = PH.PostId 
    WHERE 
        P2.PostTypeId = 2  
),
UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        SUM(COALESCE(P.Score, 0)) AS TotalPostScore,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  
    GROUP BY 
        U.Id, U.DisplayName
),
PopularQuestions AS (
    SELECT 
        Q.Title,
        Q.Score,
        U.DisplayName,
        ROW_NUMBER() OVER (ORDER BY Q.Score DESC) AS PopularityRank
    FROM 
        Posts Q
    JOIN 
        Users U ON Q.OwnerUserId = U.Id
    WHERE 
        Q.PostTypeId = 1 AND Q.Score > 10  
),
PostCloseReasons AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.Comment AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10  
)
SELECT 
    PH.PostId,
    PH.Title AS QuestionTitle,
    PH.Score AS QuestionScore,
    PH.CreationDate AS QuestionCreationDate,
    PH.Level AS AnswerLevel,
    US.DisplayName AS TopUser,
    US.TotalPosts AS UserPostCount,
    PQ.PopularityRank AS QuestionPopularity,
    PCR.CloseReason AS PostCloseReason
FROM 
    PostHierarchy PH
LEFT JOIN 
    UserScore US ON PH.PostId = US.UserId 
LEFT JOIN 
    PopularQuestions PQ ON PH.Title = PQ.Title 
LEFT JOIN 
    PostCloseReasons PCR ON PH.PostId = PCR.PostId
WHERE 
    (PQ.PopularityRank IS NOT NULL OR PCR.CloseReason IS NOT NULL)
ORDER BY 
    PH.Level, PQ.PopularityRank, PH.Score DESC;
