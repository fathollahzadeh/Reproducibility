
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        BadgeCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        UserReputation
    WHERE 
        Reputation > 1000
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.BadgeCount,
    U.UpVoteCount,
    U.DownVoteCount,
    T.TagName,
    T.PostCount AS TagPostCount
FROM 
    HighReputationUsers U
JOIN 
    PopularTags T ON T.PostCount > 10
ORDER BY 
    U.Reputation DESC, 
    TagPostCount DESC;
