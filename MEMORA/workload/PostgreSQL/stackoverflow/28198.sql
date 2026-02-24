
WITH TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountySpent,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
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
        ts.AverageScore,
        RANK() OVER (ORDER BY ts.PostCount DESC) AS TagRank
    FROM 
        TagStatistics ts
)
SELECT 
    te.TagName,
    te.PostCount,
    te.QuestionCount,
    te.AnswerCount,
    te.TotalViews,
    te.AverageScore,
    ue.DisplayName,
    ue.TotalPosts,
    ue.TotalComments,
    ue.TotalBountySpent,
    ue.UpVotesReceived,
    ue.DownVotesReceived
FROM 
    TopTags te
JOIN 
    UserEngagement ue ON ue.UserId IN (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Tags LIKE '%' || te.TagName || '%'
    )
WHERE 
    te.TagRank <= 10
ORDER BY 
    te.PostCount DESC, ue.TotalPosts DESC;
