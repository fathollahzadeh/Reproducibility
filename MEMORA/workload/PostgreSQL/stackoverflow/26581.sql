
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.Tags
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TrendingTags AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS UsageCount
    FROM 
        Tags tag
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', tag.TagName, '%')
    GROUP BY 
        tag.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    ue.DisplayName AS Owner,
    tp.TagCount,
    tt.TagName,
    ue.UpVotes,
    ue.DownVotes
FROM 
    TaggedPosts tp
JOIN 
    UserEngagement ue ON tp.OwnerUserId = ue.UserId
JOIN 
    TrendingTags tt ON tp.Tags LIKE CONCAT('%', tt.TagName, '%')
ORDER BY 
    tp.CreationDate DESC, 
    ue.UpVotes DESC;
