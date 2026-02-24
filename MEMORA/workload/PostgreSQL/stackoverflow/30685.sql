
WITH RecursiveUserContribution AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(P.Id) AS PostCount, 
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(P.Score) DESC) AS Rank,
        COALESCE(U.LastAccessDate, U.CreationDate) AS LastActiveDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.LastAccessDate, U.CreationDate
),
UserBadges AS (
    SELECT 
        B.UserId, 
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS TagsList
    FROM 
        Posts P
    CROSS JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(P.Tags FROM 2 FOR LENGTH(P.Tags) - 2), '> <')) AS T(TagName)
    GROUP BY 
        P.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UC.PostCount, 0) AS TotalPosts,
    COALESCE(UC.Questions, 0) AS TotalQuestions,
    COALESCE(UC.Answers, 0) AS TotalAnswers,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    UC.TotalBounties,
    UC.LastActiveDate,
    PT.TagsList
FROM 
    Users U
LEFT JOIN 
    RecursiveUserContribution UC ON U.Id = UC.UserId
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    PostTags PT ON P.Id = PT.PostId
WHERE 
    UC.Rank IS NULL OR UC.Rank <= 10
ORDER BY 
    U.Reputation DESC, 
    UC.TotalBounties DESC;
