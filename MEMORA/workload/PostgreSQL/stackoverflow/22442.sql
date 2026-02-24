
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT C.Id) AS TotalComments,
        DENSE_RANK() OVER (ORDER BY SUM(P.Score) DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalQuestions,
        TotalAnswers,
        TotalBounty,
        TotalComments,
        ReputationRank
    FROM UserActivity
    WHERE TotalQuestions > 0 OR TotalAnswers > 0
),
TagsCount AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS AssociatedPostCount
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.Id, T.TagName
)
SELECT 
    U.DisplayName,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalBounty,
    U.TotalComments,
    U.ReputationRank,
    COALESCE(TC.TagName, 'No Tags') AS MostAssociatedTag,
    COALESCE(TC.AssociatedPostCount, 0) AS TagPostCount,
    CASE
        WHEN U.TotalQuestions >= 10 THEN 'High Contributor'
        WHEN U.TotalQuestions BETWEEN 5 AND 9 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorType
FROM TopUsers U
LEFT JOIN (
    SELECT 
        P.OwnerUserId AS UserId,
        TagId,
        TagName,
        AssociatedPostCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY AssociatedPostCount DESC) AS rn
    FROM TagsCount
    INNER JOIN Posts P ON P.Tags LIKE CONCAT('%', TagsCount.TagName, '%')
) TC ON U.UserId = TC.UserId AND TC.rn = 1
ORDER BY U.ReputationRank;
