
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        MAX(P.CreationDate) AS LastPostDate,
        ARRAY_AGG(DISTINCT T.TagName) AS TagsUsed
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    LEFT JOIN
        (SELECT Id, UNNEST(string_to_array(Tags, '><')) AS TagName FROM Posts WHERE Tags IS NOT NULL) T ON T.Id = P.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounty,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        LastPostDate,
        TagsUsed,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC, Reputation DESC) AS UserRank
    FROM 
        UserEngagement
)

SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.TotalPosts,
    RU.TotalAnswers,
    RU.TotalBounty,
    RU.TagsUsed,
    CASE 
        WHEN RU.TotalQuestions > 0 THEN 
            (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = RU.UserId AND P.AcceptedAnswerId IS NOT NULL) 
        ELSE 
            0 
    END AS AcceptedAnswers,
    COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.UserId = RU.UserId), 0) AS TotalComments,
    CASE 
        WHEN RU.LastPostDate IS NOT NULL AND RU.LastPostDate < '2024-10-01 12:34:56'::timestamp - INTERVAL '1 YEAR' THEN 'Inactive for over a year'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    RankedUsers RU
WHERE 
    RU.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    RU.UserRank
LIMIT 10;
