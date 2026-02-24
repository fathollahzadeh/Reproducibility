
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes 
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        t.TagName
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
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
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.TotalViews,
        ts.TotalUpVotes,
        ts.TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY ts.PostCount DESC) AS TagRank
    FROM 
        TagStats ts
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.UpVotes,
        us.DownVotes,
        ROW_NUMBER() OVER (ORDER BY us.UpVotes DESC) AS UserRank
    FROM 
        UserStats us
)
SELECT
    tt.TagName,
    tt.PostCount AS TagPostCount,
    tt.QuestionCount AS TagQuestionCount,
    tt.AnswerCount AS TagAnswerCount,
    tt.TotalViews AS TagTotalViews,
    tt.TotalUpVotes AS TagTotalUpVotes,
    tt.TotalDownVotes AS TagTotalDownVotes,
    tu.DisplayName AS TopUserDisplayName,
    tu.TotalPosts AS UserTotalPosts,
    tu.UpVotes AS UserUpVotes,
    tu.DownVotes AS UserDownVotes
FROM 
    TopTags tt
JOIN 
    TopUsers tu ON tt.TagRank = 1 AND tu.UserRank = 1
WHERE 
    tt.PostCount > 0
ORDER BY 
    tt.TotalViews DESC, tt.TagName;
