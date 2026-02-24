WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(V.BountyAmount) AS AvgBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),

PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(DISTINCT PH.Id) AS HistoryChanges,
        MIN(PH.CreationDate) AS FirstChangeDate,
        MAX(PH.CreationDate) AS LastChangeDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),

UserPostSummary AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViewCount,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COALESCE(SUM(P.AnswerCount), 0) AS TotalAnswerCount,
        COALESCE(SUM(P.CommentCount), 0) AS TotalCommentCount,
        PH.HistoryChanges,
        PH.FirstChangeDate,
        PH.LastChangeDate,
        PH.CloseReopenCount
    FROM 
        UserReputation U
    LEFT JOIN 
        Posts P ON U.UserId = P.OwnerUserId
    LEFT JOIN 
        PostHistoryStats PH ON P.Id = PH.PostId
    GROUP BY 
        U.UserId, U.DisplayName, U.Reputation, PH.HistoryChanges, PH.FirstChangeDate, PH.LastChangeDate, PH.CloseReopenCount
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalViewCount,
    U.TotalScore,
    U.TotalAnswerCount,
    U.TotalCommentCount,
    U.HistoryChanges,
    U.FirstChangeDate,
    U.LastChangeDate,
    U.CloseReopenCount,
    CASE 
        WHEN U.TotalViewCount > 1000 THEN 'Highly viewed'
        ELSE 'Moderately viewed'
    END AS ViewStatus,
    CASE 
        WHEN U.TotalAnswerCount > 50 THEN 'Expert'
        WHEN U.TotalAnswerCount BETWEEN 10 AND 50 THEN 'Intermediate'
        ELSE 'Novice'
    END AS ExpertiseLevel
FROM 
    UserPostSummary U
ORDER BY 
    U.Reputation DESC, U.TotalScore DESC
LIMIT 10;
