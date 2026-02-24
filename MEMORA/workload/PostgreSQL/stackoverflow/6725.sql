WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(CM.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3) 
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalComments,
        TotalBounty,
        TotalViews,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalComments,
    TU.TotalBounty,
    TU.TotalViews,
    TU.TotalUpVotes,
    TU.TotalDownVotes,
    HP.TotalQuestionsAnswered
FROM 
    TopUsers TU
LEFT JOIN 
    (SELECT 
         OwnerUserId, 
         COUNT(DISTINCT P.Id) AS TotalQuestionsAnswered
    FROM 
         Posts P
    WHERE 
         P.PostTypeId = 2 AND P.ParentId IS NOT NULL
    GROUP BY 
         OwnerUserId) HP ON TU.UserId = HP.OwnerUserId
WHERE 
    TU.UserRank <= 10;