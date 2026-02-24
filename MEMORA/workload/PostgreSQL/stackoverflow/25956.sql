
WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 0
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCreated,
        UpvotesReceived,
        DownvotesReceived,
        ROW_NUMBER() OVER (ORDER BY PostsCreated DESC) AS UserRank
    FROM 
        UserEngagement
    WHERE 
        PostsCreated > 0
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tu.DisplayName AS TopUser,
    tu.PostsCreated,
    tu.UpvotesReceived,
    tu.DownvotesReceived
FROM 
    TopTags tt
JOIN 
    TopUsers tu ON tt.TagRank = tu.UserRank
WHERE 
    tt.TagRank <= 10
ORDER BY 
    tt.PostCount DESC, tu.PostsCreated DESC;
