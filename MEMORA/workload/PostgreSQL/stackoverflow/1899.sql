WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagPostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditRank
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5) 
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    P.Title,
    P.Tags,
    REPLACE(REPLACE(P.Body, '<br>', ' '), '</p>', '') AS CleanedBody,
    RANK() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS LatestActivity,
    Tag.TagName,
    E.CreationDate AS LastEditDate,
    E.UserId AS LastEditedBy
FROM 
    UserStats U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
JOIN 
    PopularTags Tag ON P.Tags LIKE '%' || Tag.TagName || '%'
LEFT JOIN 
    RecentEdits E ON P.Id = E.PostId AND E.EditRank = 1
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    AND P.Body IS NOT NULL
ORDER BY 
    U.Reputation DESC, P.CreationDate DESC
LIMIT 100;