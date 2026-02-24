
WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE 
                WHEN v.VoteTypeId = 2 THEN 1 
                WHEN v.VoteTypeId = 3 THEN -1 
                ELSE 0 
            END) AS ReputationScore, 
        COUNT(DISTINCT p.Id) AS AnswerPostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    WHERE 
        p.PostTypeId = 2
    GROUP BY 
        u.Id, u.DisplayName
), 
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 5
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        ReputationScore,
        AnswerPostCount,
        RANK() OVER (ORDER BY ReputationScore DESC) AS UserRank
    FROM 
       UserReputation
    WHERE 
        ReputationScore > 0
)
SELECT 
    t.TagName, 
    t.PostCount, 
    u.DisplayName AS TopUser, 
    u.ReputationScore,
    t.TagRank,
    u.UserRank
FROM 
    TopTags t
JOIN 
    TopUsers u ON u.AnswerPostCount > 10
WHERE 
    t.TagRank <= 10 AND u.UserRank <= 20
ORDER BY 
    t.PostCount DESC, u.ReputationScore DESC;
