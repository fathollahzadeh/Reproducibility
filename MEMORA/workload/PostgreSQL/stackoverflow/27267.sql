
WITH TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 10 
),
HighScoringPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    GROUP BY 
        p.Id, p.Title, p.Score, pt.Name, u.DisplayName
    HAVING 
        p.Score > 20 
)
SELECT 
    ts.Tag,
    ts.PostCount,
    u.UserId,
    u.DisplayName AS MostActiveUser,
    u.TotalPosts,
    u.QuestionCount,
    u.AnswerCount,
    hp.Id AS HighScoringPostId,
    hp.Title AS HighScoringPostTitle,
    hp.Score AS HighScoringPostScore,
    hp.PostType AS HighScoringPostType,
    hp.OwnerDisplayName AS HighScoringPostOwner
FROM 
    TagStats ts
JOIN 
    MostActiveUsers u ON ts.PostCount = (SELECT MAX(PostCount) FROM TagStats)
LEFT JOIN 
    HighScoringPosts hp ON hp.Score = (SELECT MAX(Score) FROM HighScoringPosts)
ORDER BY 
    ts.PostCount DESC, u.TotalPosts DESC, hp.Score DESC
LIMIT 10;
