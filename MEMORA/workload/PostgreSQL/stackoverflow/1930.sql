WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(V.BountyAmount) AS TotalBounties,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopContributors AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalBounties,
        ReputationRank
    FROM 
        UserStatistics
    WHERE 
        PostCount > 20
        AND ReputationRank <= 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COALESCE(MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END), '1970-01-01') AS ClosestCloseDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.AnswerCount,
    T.QuestionCount,
    T.TotalBounties,
    COUNT(DISTINCT PD.PostId) AS TotalPosts,
    SUM(PD.Score) AS TotalScore,
    AVG(PD.ViewCount) AS AverageViewCount,
    STRING_AGG(DISTINCT PD.Title, ', ') AS PostTitles,
    COUNT(CASE WHEN PD.ClosestCloseDate IS NOT NULL THEN 1 END) AS ClosedPosts
FROM 
    TopContributors T
JOIN 
    PostDetails PD ON T.UserId = PD.PostId
GROUP BY 
    T.UserId, T.DisplayName, T.Reputation, T.PostCount, T.AnswerCount, T.QuestionCount, T.TotalBounties
HAVING 
    AVG(PD.ViewCount) > 100
ORDER BY 
    T.Reputation DESC;
