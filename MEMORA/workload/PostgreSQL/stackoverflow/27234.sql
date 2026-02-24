
WITH TagCounts AS (
    SELECT 
        TRIM(REGEXP_REPLACE(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')), '<[^>]+', '', 'g')) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostsCount, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserReputation
)
SELECT 
    TT.TagName,
    TT.PostCount,
    TU.DisplayName AS TopUserName,
    TU.Reputation AS TopUserReputation,
    TU.PostsCount AS TopUserPosts,
    TU.UpVotes AS TopUserUpVotes,
    TU.DownVotes AS TopUserDownVotes
FROM 
    TopTags TT
JOIN 
    TopUsers TU ON TT.TagRank = 1
WHERE 
    TU.PostsCount > 5
ORDER BY 
    TT.PostCount DESC, TU.Reputation DESC;
