
WITH TagFrequency AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagFrequency
    WHERE 
        PostCount > 5 
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.QuestionCount,
    U.TotalBounty,
    T.TagName,
    T.PostCount
FROM 
    UserReputation U
JOIN 
    PopularTags T ON T.TagName IN (
        SELECT 
            unnest(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><'))
        FROM 
            Posts P
        WHERE 
            P.OwnerUserId = U.UserId AND P.PostTypeId = 1
    )
WHERE 
    U.Reputation > 1000 
ORDER BY 
    U.Reputation DESC, T.PostCount DESC;
