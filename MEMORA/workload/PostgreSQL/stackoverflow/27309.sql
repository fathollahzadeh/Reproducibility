WITH RankedUserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS UserRank
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, r.TotalPosts, r.QuestionCount, r.AnswerCount
    FROM Users u
    JOIN RankedUserPosts r ON u.Id = r.OwnerUserId
    WHERE r.UserRank <= 10  
),
PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        t.TagName,
        COUNT(*) AS TagCount
    FROM Posts p
    JOIN UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    GROUP BY p.Id, t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        SUM(TagCount) AS TotalTagCount
    FROM PostTagCounts
    GROUP BY TagName
    ORDER BY TotalTagCount DESC
    LIMIT 5  
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    tg.TagName,
    tg.TotalTagCount
FROM TopUsers tu
JOIN TopTags tg ON tg.TagName IN (SELECT UNNEST(string_to_array(tg.TagName, ' ')))
ORDER BY tu.Reputation DESC, tg.TotalTagCount DESC;