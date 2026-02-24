
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
), TagStatistics AS (
    SELECT 
        TagName,
        COUNT(*) AS TagFrequency,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        ProcessedTags
    JOIN 
        Posts p ON ProcessedTags.PostId = p.Id
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagFrequency,
        TotalViews,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TagFrequency DESC, TotalViews DESC) AS Rank
    FROM 
        TagStatistics
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        CommentCount,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC, UpVotes DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    t.TagName,
    t.TagFrequency,
    t.TotalViews,
    t.TotalScore,
    u.DisplayName AS TopUser,
    u.QuestionCount,
    u.CommentCount,
    u.UpVotes AS UserUpVotes,
    u.DownVotes AS UserDownVotes
FROM 
    TopTags t
JOIN 
    ActiveUsers u ON t.TagName IN (
        SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) 
        FROM Posts p 
        WHERE p.OwnerUserId = u.UserId AND p.PostTypeId = 1
    ) 
WHERE 
    t.Rank <= 10 
    AND u.UserRank <= 5 
ORDER BY 
    t.TagFrequency DESC, u.UpVotes DESC;
